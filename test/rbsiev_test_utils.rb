# frozen_string_literal: true

module RbsievTestUtils

  def scm2ast(source)
    lexer = Rbscmlex.lexer(source)
    parser = Rubasteme.parser
    parser.parse(lexer)
  end

end
