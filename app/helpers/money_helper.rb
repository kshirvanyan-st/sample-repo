module MoneyHelper
  # 12500 → "12 500 ֏"
  def amd(amount)
    "#{number_with_delimiter(amount, delimiter: " ")} ֏"
  end
end
