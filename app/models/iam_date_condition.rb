class IamDateCondition < IamCondition
    allowed_operators "DateEquals", "DateNotEquals", "DateLessThan", "DateLessThanEquals", "DateGreaterThan", "DateGreaterThanEquals"
end
