module PublishingEventPipeline
  module Helpers
    module Extract
      # Given several path strings, extracts and flattens all values found in the hash and combines
      # them into a single string with a separator.
      def extract_all(hash, path_strings, separator: "\n")
        values = path_strings.map { json_path(_1).on(hash) }
        values.flatten.join(separator)
      end

      # Given several path strings, extracts the first present value found in the hash.
      def extract_first(hash, path_strings)
        values = path_strings.lazy.map { json_path(_1).first(hash) }
        values.find(&:present?)
      end

      # Extracts a single value from a hash given a path string.
      def extract_single(hash, path_string)
        json_path(path_string).first(hash)
      end

      # Creates or retrieves a cached JsonPath object given a path string.
      def json_path(path_string)
        self.class.cached_json_paths[path_string] ||= JsonPath.new(path_string)
      end

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        # Caches JsonPath objects at class level to avoid creating them repeatedly for every new
        # consumer object.
        def cached_json_paths
          @cached_json_paths ||= {}
        end
      end
    end
  end
end
