require 'mathviz'

class Numeric
  def between(range)
    [[self.to_f, range.max].min - range.min, 0].max
  end
end

class Range
  include MathViz::Measurable
end

MathViz.new {
  new_units :usd
  binop :between

  def pos(n)
    n.max(0.usd)
  end

  When "I earn"
  income = 39_527.usd

  And "spend"
  medical = 6_153.usd
  contributions = 2_189.usd
  property_tax = 3_830.usd
  interest_paid = 9_055.usd
  us_tax_paid = 7000.usd
  il_tax_paid = 1800.usd

  Given "IL tax rates (2012)"
  il = const 0.05
  il_deduction = 2000.usd

  Then "IL tax"
  il_deductions = (il_deduction + property_tax)

  il_taxable = pos(income - il_deductions)
  il_tax = il_taxable * il
  il_tax_due = il_tax - il_tax_paid

  Given "US tax rates (2012)"
  ss = const 0.104
  medicare = const 0.029
  tax_brackets = {
    0.10 => (0..8_700).usd,
    0.15 => (8_700..35_350).usd,
    0.25 => (35_350..85_650).usd,
    0.28 => (85_650..178_650).usd,
    0.33 => (178_650..388_350).usd,
  }
  standard_deduction = 5_950.usd
  exception = 3_800.usd

  Then "US tax"
  ss_tax = income * ss
  medicare_tax = income * medicare
  welfare_tax = ss_tax + medicare_tax

  itemized_deduction = property_tax + il_tax_paid + interest_paid + contributions
  deduction = itemized_deduction.max(standard_deduction)
  us_deductions = deduction + exception
  us_taxable = pos(income - ss_tax/2 - medical - us_deductions)

  # this removes some noise from the graph
  applicable_brackets = tax_brackets.select do |rate, bracket|
    bracket.to_value.min <= us_taxable.to_value
  end
  us_income_tax = applicable_brackets.map do |rate, bracket|
    us_taxable.between(bracket) * rate
  end.reduce(&:+)

  us_tax = us_income_tax + welfare_tax
  us_tax_due = us_tax - us_tax_paid

  binding
}.dot
