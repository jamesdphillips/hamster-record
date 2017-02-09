module Hamster
  require "hamster/hash"
  require_relative "./record_config"

  # Hamster::Record
  #
  # Simple Immutable Stuct/Record-ish implementation for Ruby using
  # Hamster::Hash. Has similar interface to that of Ruby Structs but
  # allows for default values to be provided similar to Elixir Structs.
  # Strives for better performance & API than Hamsterdam and Imutable-Ruby.
  #
  # Usage:
  #
  #   Person  = Hamster::Record.define(:name, :age)
  #   Address = Hamster::Record.define do
  #     field :lines, C::ArrayOf[String]
  #     field :country, String, "Canada"
  #     field :current, default: true # alternative syntax
  #     field :state, String
  #     field :city, String
  #   end
  #
  module Record
    include Contracts::Core

    extend self

    # Allow type checking to be disabled for perf reasons
    DISABLE_TYPES = !ENV["DISABLE_TYPES"].nil?

    Contract C::Args[Symbol] => Class
    def define(*fields)
      config = RecordConfig.new(fields)
      config.freeze
      build(config)
    end

    Contract Proc => Class
    def define(&block)
      config = RecordConfig.new
      config.instance_eval(&block)
      config.freeze
      build(config)
    end

    private

    Contract RecordConfig => Class
    def build(config)
      record_kls = define_class(config)
      record_kls = define_readers(record_kls, config.fields)
      record_kls = define_contract(record_kls, config.types)
      record_kls.const_set(:FIELDS, config.fields)
      record_kls.const_set(:DEFAULTS, config.defaults)
      record_kls.const_set(:TYPES, config.types)
      # record_kls.freeze # TODO: possibly allow this to be configured
      record_kls
    end

    Contract RecordConfig => Class
    def define_class(config)
      if !DISABLE_TYPES && config.types.any?
        abstract = TypedAbstract
      elsif config.defaults.any?
        abstract = Abstract
      else
        abstract = Hamster::Hash
      end
      Class.new(abstract)
    end

    Contract Class, C::ArrayOf[Symbol] => Class
    def define_readers(kls, fields)
      fields.each do |field|
        kls.send(:define_method, field) { get(field) }
      end
      kls
    end

    Contract Class, C::HashOf[Symbol, C::Any] => Class
    def define_contract(kls, types)
      # Given types defines a new contract on the record class
      # and applies it to the initialize instance method
      if kls.superclass == TypedAbstract
        kls.Contract(C::Shape[types] => kls)
        Contracts::MethodHandler.new(:new, true, kls).handle
      end
      kls
    end

    # Merges in any defaults given. Uses mutatable merge on empty hash
    # as it appears to give us slightly better performance.
    class Abstract < Hamster::Hash
      def initialize(pairs, &block)
        super({}.merge!(self.class::DEFAULTS).merge!(pairs), &block)
      end

      # Validate the shape of the data before given
      def self.valid?(vals)
        C::Shape[self::TYPES].valid?(vals)
      end
    end

    class TypedAbstract < Abstract
      # TODO: Dynamically include if TYPES are enabled; that way we can avoid
      # loading Contracts library entirely in environments where it is not needed
      include Contracts::Core

      # Override #alloc to ensure we type check updates. Performance may
      # be improved with a special Hamster::Tire Contract type.
      #
      # Example:
      #
      #   Assume `field :my_string, String`; the following would raise
      #   a Contract violation:
      #
      #   >> record = MyRecord.new(my_string: "123")
      #   >> record.put(:my_string, 123)
      #   => ParamContractError: Contract violation
      def self.alloc(pairs, block = nil)
        new(Hamster::Hash.alloc(pairs), &block)
      end
    end
  end
end
