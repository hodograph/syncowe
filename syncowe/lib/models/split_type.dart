/// The method of splitting the remainder of a transaction.
enum SplitType
{
  /// Evenly split remainder of transaction amount amongst all debtors and the payer.
  evenSplit("Even Split"),

  /// Proportionally split remainder of transaction amount amongst all debtors based on how much they owe.
  proportionalSplit("Proportional Split"),

  /// The payer pays the remainder of the transaction amount.
  payerPays("Payer Pays");

  final String name;
  const SplitType(this.name);
}