**KipuBank**

KipuBank es un contrato inteligente en Solidity que implementa un sistema de bóvedas personales para depósitos y retiros de ETH.
Cada usuario puede depositar fondos en su propia bóveda y retirarlos bajo ciertas condiciones, garantizando un límite global de capacidad del banco y un umbral máximo de retiro por transacción.

**Características principales**

  Depósitos de ETH en bóvedas personales.
  
  Retiros limitados por un umbral máximo por transacción.
  
  Límite global de capacidad del banco (capacidad total de ETH que puede mantener).
  
  Eventos emitidos en cada depósito y retiro exitoso.
  
  Contadores de depósitos y retiros realizados.
  
  Manejo de errores personalizados para validar operaciones inválidas.

**Despliegue**

Al desplegar el contrato se deben definir dos parámetros:

_bankCap → Capacidad máxima de ETH que puede mantener el contrato (en wei).

_umbralRetiro → Monto máximo permitido por transacción para un retiro (en wei).

Condiciones de inicialización

Ambos parámetros deben ser mayores a cero.

_bankCap debe ser mayor o igual a _umbralRetiro.

Ejemplo válido

bankCap = 10 ether

umbralRetiro = 1 ether

Ejemplo inválido

bankCap = 0

umbralRetiro = 0

bankCap < umbralRetiro

**Interacción con el contrato**
Depósitos

  Un usuario puede enviar ETH al contrato mediante:
  
  La función depositar().
  
  Enviando directamente ETH al contrato (vía receive o fallback).

Retiros

  La función retirar(uint256 monto) permite retirar fondos de la bóveda personal, siempre que:
  
  El monto no supere el saldo de la bóveda.
  
  El monto no supere el umbral de retiro definido en el despliegue.

Consultas disponibles

  verSaldo() → Devuelve el saldo de la bóveda del usuario que llama.
  
  verContDepositos() → Devuelve la cantidad total de depósitos realizados.
  
  verContRetiros() → Devuelve la cantidad total de retiros realizados.
  
  verBalanceContrato() → Devuelve el balance total del contrato.

Eventos

  KipuBank_DepositoAceptado(address usuario, uint256 monto)
  
  KipuBank_RetiroAceptado(address usuario, uint256 monto)
