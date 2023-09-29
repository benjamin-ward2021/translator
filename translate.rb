class Translator
  class Word
    attr_accessor :pos, :language, :word
    def initialize(pos, language, word)
      @pos = pos
      @language = language
      @word = word
    end

    def ==(other)
      # if the other word has a ? then ignore that field for comparison
      pos = @pos == other.pos || @pos == "?" || other.pos == "?"
      language = @language == other.language || @language == "?" || other.language == "?"
      word = @word == other.word || @word == "?" || other.word == "?"

      pos && language && word
    end
  end

  class Lexicon
    attr_accessor :translations, :grammar

    def initialize
      # Hash(words in english => Array(words in other languages))
      @translations = {}

      # Hash(Languages => Array(pos in order))
      @grammar = {}
    end
  end

  def initialize(words_file, grammar_file)
    @lexicon = Lexicon.new
    updateLexicon(words_file)
    updateGrammar(grammar_file)
  end

  # part 1

  def updateLexicon(inputfile)
    file = File.new(inputfile)
    file_text = file.read
    # example file_text:
    #     blue, ADJ, French:bleu, German:blau, Spanish:azul, Swedish:Bla
    #     truck, NOU, Spanish:camion, German:LKW
    #     the, DET, German:det, Spanish:el, French:le

    file.close
    validated_array = file_text.scan(/^([a-z-]+, [A-Z]{3}(, [A-Z][a-z0-9]*:[a-z-]+)+)$/)

    # this loop is here because scan saves the capture groups differently
    # and we only want the whole line
    for element in validated_array
      element.delete_at(1)
    end

    validated_array.flatten!

    # example validated_array:
    #     ["the, DET, German:det, Spanish:el, French:le"]
    # in this case there is only one valid line

    for line in validated_array
      split_line = line.split(', ')
      # example split_line:
      #     ["the", "DET", "German:det", "Spanish:el", "French:le"]
      # each word is a different element in the array, notice the quotes compared to validated_array 
      # (split_line[0] = "the", split_line[1] = "DET", split_line[2] = "German:det", etc...)

      pos = split_line[1]
      english_word = Word.new(pos, 'English', split_line[0])

      if !@lexicon.translations.key?(english_word)
        @lexicon.translations.store(english_word, [])
      end

      for word in split_line.drop(2)
        split_word = word.split(':')
        # example split_word:
        #     ["German", "det"]

        translated_word = Word.new(pos, split_word[0], split_word[1])
        comparison_word = Word.new(pos, split_word[0], "?")
        @lexicon.translations[english_word].delete(comparison_word)
        @lexicon.translations[english_word].push(translated_word)
      end
    end
  end

  def updateGrammar(inputfile)
    file = File.new(inputfile)
    file_text = file.read
    # example file_text:
    #     English: DET, ADJ{3}, NOU
    #     Spanish: DET, NOU, ADJ
    #     French: DET, NOU
    #     German: Det, ADJ, ADJ, NOU, ADJ

    file.close
    validated_array = file_text.scan(/^([A-Z][a-z0-9]*: ([A-Z]{3}({[0-9]+})?(, )?)+)$/)

    # this loop is here because scan saves the capture groups differently
    # and we only want the whole line
    for element in validated_array
      element.delete_at(1)
      element.delete_at(1)
      element.delete_at(1)
    end

    validated_array.flatten!
    # example validated_array:
    #     ["English: DET, ADJ{3}, NOU",
    #     "Spanish: DET, NOU, ADJ",
    #     "French: DET, NOU",
    #     "German: Det, ADJ, ADJ, NOU, ADJ"]

    for line in validated_array
      split_line = line.split(': ')
      # example split_line:
      #     ["English", "DET, ADJ{3}, NOU"]
      # this splits the language into split_line[0] and the rest into split_line[1]

      language = split_line[0]

      pos_arr = []

      split_pos = split_line[1].split(", ")

      for word in split_pos
        quantity = word.scan(/\d+/).first
        if quantity.nil?
          pos_arr.push(word)
        else
          for _ in 1..quantity.to_i
            pos_arr.push(word[0..2])
          end
        end
      end

      @lexicon.grammar.store(language, pos_arr)
    end
  end

  # part 2

  def generateSentence(language, struct)
    ret = ""

    pos_array = struct
    if !pos_array.is_a? Array
      pos_array = @lexicon.grammar[struct]
      if pos_array.nil?
        return nil
      end
    end

    for pos in pos_array
      comparison_word = Word.new(pos.dup, language, "?")
      options = @lexicon.translations.values.flatten.select{ |word| word == comparison_word }
      if language == "English"
        options = @lexicon.translations.keys.select{ |word| word == comparison_word }
      end
      if options.empty?
        return nil
      end

      # we can pick any word, I'm choosing to pick the first since we are guarenteed to have at least 1
      ret += options[0].word + " "
    end
    ret.chop
  end

  def checkGrammar(sentence, language)
    split_sentence = sentence.split
    for i in 0..split_sentence.length - 1
      comparison_word = Word.new(@lexicon.grammar[language][i], language, split_sentence[i])
      if @lexicon.translations.values.flatten.select{ |word| word == comparison_word }.empty? && language != "English"
        return false
      end
      if @lexicon.translations.keys.select{ |word| word == comparison_word }.empty? && language == "English"
        return false
      end
    end
    return true
  end

  def changeGrammar(sentence, struct1, struct2)
    ret = ""
    pos_array1 = struct1
    if !pos_array1.is_a? Array
      pos_array1 = @lexicon.grammar[struct1]
      if pos_array1.nil?
        return nil
      end

      pos_array1 = pos_array1.dup
    end

    pos_array2 = struct2
    if !pos_array2.is_a? Array
      pos_array2 = @lexicon.grammar[struct2]
      if pos_array2.nil?
        return nil
      end
    end

    split_sentence = sentence.split
    for i in 0..split_sentence.length - 1
      if pos_array1.find_index(pos_array2[i]).nil?
        return nil
      end

      ret += split_sentence[pos_array1.find_index(pos_array2[i])] + " "
      pos_array1[pos_array1.find_index(pos_array2[i])] = nil
    end
    ret.chop
  end

  # part 3
  def changeLanguage(sentence, language1, language2)
    ret = ""
    
    split_sentence = sentence.split
    for i in 0..split_sentence.length - 1
      english_options = []
      if language1 == "English"
        comparison_word = Word.new("?", "English", split_sentence[i])
        english_options = @lexicon.translations.keys.select{ |word| word == comparison_word }
        if english_options.empty?
          return nil
        end

      else
        comparison_word = Word.new("?", language1, split_sentence[i])
        english_options = @lexicon.translations.select{ |_, v| v.include?(comparison_word) }
        if english_options.empty?
          return nil
        end

        english_options = english_options.keys
      end

      if english_options.empty?
        return nil
      end

      if language2 == "English"
        ret += english_options[0].word + " "
        next
      end

      translated_options = []

      for word in english_options
        comparison_word = Word.new(word.pos, language2, "?")
        translated_options.push(@lexicon.translations[word].flatten.select{ |word| word == comparison_word })
      end

      if translated_options.empty? || translated_options[0].empty?
        return nil
      end

      ret += translated_options[0][0].word + " "
    end
    ret.chop
  end

=begin
  def changeLanguage(sentence, language1, language2)
    ret = ""

    split_sentence = sentence.split
    for i in 0..split_sentence.length - 1
      comparison_word = Word.new("?", language1, split_sentence[i])
      english_word = @lexicon.translations.select{ |k, v| v.include?(comparison_word) }
      if english_word.empty? && language1 != "English"
        return nil
      end
      if language1 == "English"
        english_word = @lexicon.translations.keys.select{ |word| word == comparison_word }
        if english_word.empty?
          puts "nil1"
          return nil
        end

        english_word = english_word[0]
      else
        english_word = english_word.keys[0]
      end
      if english_word.nil?
        puts "nil2"
        return nil
      end

      comparison_word = Word.new(english_word.pos, language2, "?")
      translated_word = @lexicon.translations[english_word].flatten.select{ |word| word == comparison_word }
      if language2 == "English"
        translated_word = @lexicon.translations.keys.select{ |word| word == comparison_word }
        if translated_word.empty?
          return nil
        end
      end
      if translated_word.empty?
        puts "nil3"
        return nil
      else
        translated_word = translated_word[0]
      end

      ret += translated_word.word + " "
    end
    ret.chop
  end
=end

  def translate(sentence, language1, language2)
    fix_grammar = changeGrammar(sentence, language1, language2)
    if fix_grammar.nil?
      return nil
    end
    translate = changeLanguage(fix_grammar, language1, language2)
    if translate.nil?
      return nil
    end
    translate
  end
end
