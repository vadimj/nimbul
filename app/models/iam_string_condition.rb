class IamStringCondition < IamCondition
    allowed_operators "StringEquals", "StringNotEquals", "StringEqualsIgnoreCase", "StringNotEqualsIgnoreCase", "StringLike", "StringNotLike"
end
