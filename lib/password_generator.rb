class PasswordGenerator
  DIGITS      = ('0'..'9').to_a
  UPPER_ALPHA = ('A'..'Z').to_a
  LOWER_ALPHA = ('a'..'z').to_a
  SYMBOLS     = %w(~ ! @ # $ % ^ & * _ - + = [ ] { } | : ; < , > . ?)

  DIGIT       = 0x01
  ALPHA_UPPER = 0x02
  ALPHA_LOWER = 0x04
  SYMBOL      = 0x08

  CHARACTERS = {
    DIGIT => DIGITS,
    ALPHA_UPPER => UPPER_ALPHA,
    ALPHA_LOWER => LOWER_ALPHA,
    SYMBOL => SYMBOLS
  }
  
  ALPHA               = ALPHA_LOWER | ALPHA_UPPER
  ALPHA_NUMERIC       = DIGIT | ALPHA
  ALPHA_NUMERIC_UPPER = DIGIT | ALPHA_UPPER
  ALPHA_NUMERIC_LOWER = DIGIT | ALPHA_LOWER
  
  ALL_SYMBOLS = ALPHA_NUMERIC | SYMBOL
  
  DEFAULT_LENGTH = 16
  
  def self.generate flags = ALL_SYMBOLS, length = DEFAULT_LENGTH
    sigils = []
    length.times do 
      [ DIGIT, ALPHA_UPPER, ALPHA_LOWER, SYMBOL ].each do |flag|
        if flags & flag == flag
          sigil = ( CHARACTERS[flag][rand(CHARACTERS[flag].size)] ) 
          sigils << sigil unless sigil.nil? or sigil == ' '
        end
      end
    end
    sigils.sort_by { rand }.join[0,length]
  end
end
