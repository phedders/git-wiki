module Wiki

  class Cache
    class<< self
      attr_accessor :instance

      def cache(bucket, key, opts = {}, &block)
        instance.cache(bucket, key, opts, &block)
      end
    end

    # Simple string caching
    def cache(bucket, key, opts = {}, &block)
      return yield if opts[:disable]
      return read(bucket, key) if exist?(bucket, key) && !opts[:update]
      content = yield
      write(bucket, key, content)
      content
    end

    class Disk < Cache
      attr_reader :root

      def initialize(root)
        @root = root
        FileUtils.mkdir_p root, :mode => 0755
      end

      def exist?(bucket, key)
        File.exist?(cache_path(bucket, key))
      end

      def read(bucket, key)
        File.read(cache_path(bucket, key))
      rescue Errno::ENOENT
        nil
      end

      def open(bucket, key)
        BlockFile.open(cache_path(bucket, key), 'rb')
      rescue Errno::ENOENT
        nil
      end

      def write(bucket, key, content)
        temp_file = File.join(root, ['tmp', $$, Thread.current.object_id.abs.to_s(36)].join('-'))
        File.open(temp_file, 'wb') do |dest|
          content.each do |part|
            dest.write(part)
          end
        end

        path = cache_path(bucket, key)
        if File.exist?(path)
          File.unlink temp_file
        else
          FileUtils.mkdir_p File.dirname(path), :mode => 0755
          FileUtils.mv temp_file, path
        end
        true
      rescue
        File.unlink temp_file rescue false
        false
      end

      def remove(bucket, key)
        File.unlink cache_path(bucket, key)
      rescue Errno::ENOENT
      end

      protected

      class BlockFile < ::File #:nodoc:
        def each
          rewind
          while part = read(8192)
            yield part
          end
        end
      end

      def cache_path(bucket, key)
        File.join(root, bucket, key)
      end
    end

  end
end
