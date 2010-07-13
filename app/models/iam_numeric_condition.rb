class IamNumericCondition < IamCondition
    allowed_operators "NumericEquals", "NumericNotEquals", "NumericLessThan", "NumericLessThanEquals", "NumericGreaterThan", "NumericGreaterThanEquals"
end
