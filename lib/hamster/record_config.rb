module Hamster
  class RecordConfig
    include Contracts::Core

    attr_reader :fields, :defaults, :types

    Contract C::Maybe[C::ArrayOf[Symbol]] => C::Any
    def initialize(fields = [])
      @fields = fields
      @defaults = {}
      @types = {}
    end

    def freeze
      @defaults.freeze
      @fields.freeze
      @types.freeze
      super
    end

    private

    Contract Symbol => C::Any
    def field(name)
      field(name, nil, nil)
    end

    Contract Symbol, C::Contract, C::Any => C::Any
    def field(name, type, default = nil)
      field(name, type: type, default: default)
    end

    Contract Symbol, C::KeywordArgs[type: C::Contract, default: C::Any] => C::Any
    def field(name, type: nil, default: nil)
      @defaults[name] = default unless default.nil?
      @types[name] = type unless type.nil?
      @fields << name
    end
  end
end
