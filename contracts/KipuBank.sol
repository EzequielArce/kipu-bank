// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title KipuBank - Bóvedas personales con límite de banco y umbral de retiro
/// @author Ezequiel Arce
/// @notice Contrato simple para depositar/retirar ETH con límites y errores personalizados
contract KipuBank {

    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Bóvedas por usuario (saldo en wei)
    mapping(address usuario => uint256 ) private s_bovedas;

    /// @notice Límite total del banco (capacidad global) en wei, fijado en deploy
    uint256 public immutable i_bankCap;

    /// @notice Umbral máximo de retiro por transacción (wei), fijado en deploy
    uint256 public immutable i_umbralRetiro;

    /// @notice Contador de depósitos exitosos
    uint256 private s_contDepositos;

    /// @notice Contador de retiros exitosos
    uint256 private s_contRetiros;



    /*//////////////////////////////////////////////////////////////
                                 EVENTOS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitida cuando un deposito es exitoso
    /// @param usuario quien depositó
    /// @param monto monto depositado
    event KipuBank_DepositoAceptado(address usuario, uint256 monto);

    /// @notice Emitida cunado un retiro es exitoso
    /// @param usuario quien retiró
    /// @param monto monto retirado
    event KipuBank_RetiroAceptado(address usuario, uint256 monto);




    /*//////////////////////////////////////////////////////////////
                                 ERRORES
    //////////////////////////////////////////////////////////////*/

    /// @notice Revierte cuando un monto es inválido (es menor o igual a cero)
    /// @param usuario El usuario que intento realizar una operación
    /// @param monto Cantidad que utilizó
    error KipuBank_MontoRechazado(address usuario, uint256 monto);

    /// @notice Revierte cuando un depósito es inválido (excede la capacidad global del banco)
    /// @param usuario El usuario que intentó realizar el depósito
    /// @param monto Cantidad que intentó depositar
    error KipuBank_DepositoRechazado(address usuario, uint256 monto);

    /// @notice Revierte cuando un retiro es inválido (excede el balance de la cuenta o el umbral fijo por transacción)
    /// @param usuario El usuario que intentó realizar el retiro
    /// @param monto Cantidad que intentó retirar
    error KipuBank_RetiroRechazado(address usuario, uint256 monto);

    /// @notice Revierte cuando una transferencia de ETH falla
    /// @param data Datos devueltos por la llamada
    error KipuBank_TransferenciaFallida(bytes data);

    /// @notice Revierte cuando los parámetros de inicialización son inválidos
    /// @param bankCap Valor proporcionado para el límite global del banco
    /// @param umbralRetiro Valor proporcionado para el umbral máximo de retiro
    error KipuBank_InicializacionFallida(uint256 bankCap, uint256 umbralRetiro);




    /*//////////////////////////////////////////////////////////////
                               MODIFICADORES
    //////////////////////////////////////////////////////////////*/

    /// @notice Verifica montos > 0
    modifier soloMontosMayoresQueCero(uint256 monto) {
        if (monto <= 0) revert KipuBank_MontoRechazado(msg.sender, monto);
        _;
    }




    /*//////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Inicializa el contrato con límite global y umbral de retiro
    /// @param _bankCap Cap máximo de ETH que puede mantener el contrato (wei)
    /// @param _umbralRetiro Máximo por retiro por transacción (wei)
    constructor(uint256 _bankCap, uint256 _umbralRetiro) {
        if (_bankCap == 0 || _umbralRetiro == 0 || _bankCap < _umbralRetiro)
            revert KipuBank_InicializacionFallida(_bankCap, _umbralRetiro);
        
        i_bankCap = _bankCap;
        i_umbralRetiro = _umbralRetiro;
    }




    /*//////////////////////////////////////////////////////////////
                        FUNCIONES EXTERNAS
    //////////////////////////////////////////////////////////////*/

    receive() external payable soloMontosMayoresQueCero(msg.value){
        // Llamamos a la función de depósito internamente
        _depositar(msg.sender, msg.value);
    }

    fallback() external payable soloMontosMayoresQueCero(msg.value){
        // Permitir enviar ETH usando fallback -> se considera depósito
        _depositar(msg.sender, msg.value);
    }

    /// @notice Deposita ETH en la bóveda del remitente
    /// @dev Respeta el bankCap global. Emite evento y registra contador de depósitos.
    function depositar() external payable soloMontosMayoresQueCero(msg.value) {
       _depositar(msg.sender, msg.value);
    }

    /// @notice Retira hasta `i_umbralRetiro` por transacción desde la propia bóveda
    /// @param _monto Cantidad a retirar (wei)
    function retirar(uint256 _monto) external soloMontosMayoresQueCero(_monto){
        // checks
        if (_monto > i_umbralRetiro || _monto > s_bovedas[msg.sender]) revert KipuBank_RetiroRechazado(msg.sender, _monto);

        // effects
        s_bovedas[msg.sender] -= _monto;
        s_contRetiros += 1;

        // interactions
        _transferirEth(_monto);
        emit KipuBank_RetiroAceptado(msg.sender, _monto);
    }

    /// @notice Devuelve el saldo de la bóveda del `msg.sender`
    function verSaldo() external view returns (uint256 saldo) {
        return s_bovedas[msg.sender];
    }

    /// @notice Devuelve la cantidad total de depósitos realizados en el contrato
    function verContDepositos() external view returns (uint256 cantDepositos) {
        return s_contDepositos;
    }

    /// @notice Devuelve la cantidad total de retiros realizados en el contrato
    function verContRetiros() external view returns (uint256 cantRetiros) {
        return s_contRetiros;
    }

    /// @notice Devuelve el balance total del contrato
    function verBalanceContrato() external view returns (uint256 balance) {
        return address(this).balance;
    }


    /*//////////////////////////////////////////////////////////////
                              FUNCIONES PRIVADAS
    //////////////////////////////////////////////////////////////*/

    /// @notice Transferencia segura de ETH al \"msg.sender\"
    /// @param _monto Cantidad a transferir (wei)
    function _transferirEth(uint256 _monto) private {
        (bool exito, bytes memory data) = msg.sender.call{value: _monto}("");
        if (!exito) revert KipuBank_TransferenciaFallida(data);
    }

    /**
    * @dev Lógica interna de depósito, llamada por depositar(), receive() y fallback()
    * @param usuario Quien deposita
    * @param monto Monto enviado en wei
    */
    function _depositar(address usuario, uint256 monto) private {
        if (address(this).balance > i_bankCap) {
            revert KipuBank_DepositoRechazado(usuario, monto);
        }

        
        s_bovedas[usuario] += monto;
        s_contDepositos += 1;

        
        emit KipuBank_DepositoAceptado(usuario, monto);
    }
}
