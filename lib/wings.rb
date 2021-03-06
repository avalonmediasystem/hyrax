# frozen_string_literal: true

##
# Wings is a toolkit integrating Valkyrie into Hyrax as a bridge away from the
# hard dependency on ActiveFedora.
#
# Requiring this module with `require 'wings'` injects a variety of behavior
# supporting a gradual transition from existing `ActiveFedora` models and
# persistence middleware to Valkyrie.
#
# `Wings` is primarily an isolating namespace for code intended to be removed
# after a full transition to `Valkyrie` as the persistence middleware for Hyrax.
# Applications may find it useful to depend directly on this code to facilitate
# a smooth code migration, much in the way it is being used in this engine.
# However, these dependencies should be considered temprorary: this code will
# be deprecated for removal in a future release.
#
# @example casting an ActiveFedora model to Valkyrie
#   work     = GenericWork.create(title: ['Comet in Moominland'])
#   resource = work.valkyrie_resource
#
#   resource.title # => ["Comet in Moominland"]
#   resource.title = ["Mumintrollet på kometjakt"]
#
#   Hyrax.persister.save(resource: resource)
#
#   work.reload
#   work.title # => ["Mumintrollet på kometjakt"]
#
# @example defining a native Valkyrie model for use with Wings
#   # given an `ActiveFodora` model like
#   class Book < ActiveFedora::Base
#     property :author, predicate: ::RDF::URI('http://example.com/ns/author')
#     property :title,  predicate: ::RDF::URI('http://example.com/ns/title')
#   end
#
#   # define a `Valkyrie` model with matching attributes,
#   class BookResource < Hyrax::Resource
#     attribute :author, Valkyrie::Types::String
#     attribute :title,  Valkyrie::Types::String
#   end
#
#   # and register the relationship with `Wings`
#   Wings::ModelRegistry.register(BookResource, Book)
#
#   # `Wings` will cast the `BookResource` to a `Book` to persist via `ActiveFedora`
#   resource = BookResource.new(author: 'Tove Jansson', title: 'Comet in Moominland')
#   adapter  = Wings::Valkyrie::MetadataAdapter.new
#   resource = adapter.persister.save(resource: resource)
#
#   resource.title  # => ["Comet in Moominland"]
#   resource.author # => ["Tove Jansson"]
#
#   resource.is_a?(BookResource) # => true
#
# @see https://wiki.duraspace.org/display/samvera/Hyrax-Valkyrie+Development+Working+Group
#      for further context regarding the approach
module Wings
  ##
  # @api public
  #
  # Provides a search builder for new valkyrie types that are indexed as their
  # corresponding legacy ActiveFedora classes.
  #
  # @example
  #   builder = Wings::WorkSearchBuilder(Monograph)
  def self.WorkSearchBuilder(work_type) # rubocop:disable Naming/MethodName
    Class.new(Hyrax::WorkSearchBuilder) do
      @@_legacy_type = Wings::ModelRegistry.lookup(work_type) # rubocop:disable Style/ClassVars

      def work_types
        [@@_legacy_type]
      end
    end
  end
end

require 'valkyrie'
require 'wings/model_registry'
require 'wings/model_transformer'
require 'wings/orm_converter'
require 'wings/attribute_transformer'
require 'wings/services/custom_queries/find_access_control'
require 'wings/services/custom_queries/find_file_metadata'
require 'wings/services/custom_queries/find_many_by_alternate_ids'
require 'wings/valkyrizable'
require 'wings/valkyrie/metadata_adapter'
require 'wings/valkyrie/resource_factory'
require 'wings/valkyrie/persister'
require 'wings/valkyrie/query_service'
require 'wings/valkyrie/storage/active_fedora'

Hydra::AccessControl.send(:define_method, :valkyrie_resource) do
  attrs = attributes.symbolize_keys
  attrs[:new_record]  = new_record?
  attrs[:created_at]  = create_date
  attrs[:updated_at]  = modified_date

  attrs[:permissions] = permissions.map do |permission|
    agent = permission.type == 'group' ? "group/#{permission.agent_name}" : permission.agent_name

    Hyrax::Permission.new(id: permission.id,
                          mode: permission.access.to_sym,
                          agent: agent,
                          access_to: Valkyrie::ID.new(permission.access_to_id),
                          new_record: permission.new_record?)
  end

  attrs[:access_to] = attrs[:permissions].find { |p| p.access_to&.id&.present? }&.access_to

  Hyrax::AccessControl.new(**attrs)
end

begin
  require 'wings/setup'
rescue NameError, Hyrax::SimpleSchemaLoader::UndefinedSchemaError => err
  raise(err) if ENV['RAILS_ENV'] == 'production'
  :noop
end

# some aliases for use by diners of varying sophistication
BuffaloWings = Wings
MightyWings = Wings
HotWings = Wings
SpicyWings = Wings
SwissWings = Wings
BuffaloCauliflowerWings = Wings
