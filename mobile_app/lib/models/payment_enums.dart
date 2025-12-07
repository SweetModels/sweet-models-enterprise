/// Enumeración de métodos de pago soportados
enum PaymentMethod {
  bankTransfer('Transferencia Bancaria'),
  card('Tarjeta de Crédito/Débito'),
  cash('Efectivo'),
  check('Cheque'),
  crypto('Criptomoneda'),
  other('Otro');

  const PaymentMethod(this.displayName);
  final String displayName;

  /// Obtiene el enum desde un string
  static PaymentMethod fromString(String value) {
    return PaymentMethod.values.firstWhere(
      (e) => e.displayName.toLowerCase() == value.toLowerCase() ||
             e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PaymentMethod.other,
    );
  }
}

/// Enumeración de tipos de documento
enum DocumentType {
  receipt('Recibo'),
  invoice('Factura'),
  statement('Estado de Cuenta'),
  contract('Contrato');

  const DocumentType(this.displayName);
  final String displayName;
}

/// Enumeración de monedas soportadas
enum Currency {
  cop('COP', '\$', 0),
  usd('USD', '\$', 2),
  eur('EUR', '€', 2);

  const Currency(this.code, this.symbol, this.decimalDigits);
  final String code;
  final String symbol;
  final int decimalDigits;
}
