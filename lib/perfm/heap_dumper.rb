require "rbtrace"

module Perfm
  class HeapDumper
    class Error < StandardError; end

    class << self
      def generate
        new.generate
      end
    end

    def generate
      worker_pid = find_worker_pid
      generate_dump(worker_pid)
    end

    private

      def find_worker_pid
        pid = PidStore.instance.get_first_worker_pid
        return pid if pid

        raise Error, "No Puma worker processes available"
      end

      def generate_dump(worker_pid)
        filename = "heap_dump_pid_#{worker_pid}_time_#{Time.current.to_i}.json"
        temp_path = Rails.root.join("tmp", filename)
        FileUtils.mkdir_p(File.dirname(temp_path))

        generate_heap_dump(worker_pid, temp_path)
        store_dump(temp_path, filename)
      ensure
        FileUtils.rm_f(temp_path) if defined?(temp_path) && temp_path
      end

      def generate_heap_dump(worker_pid, output_path)
        cmd = build_rbtrace_command(worker_pid, output_path)
        execute_rbtrace(cmd)
      end

      def build_rbtrace_command(worker_pid, output_path)
        <<~COMMAND
          rbtrace -p #{worker_pid} -e '
            Thread.new {
              require "objspace"
              ObjectSpace.trace_object_allocations_start
              GC.start
              File.open("#{output_path}", "w") { |f| 
                ObjectSpace.dump_all(output: f)
              }
            }.join
          '
        COMMAND
      end

      def execute_rbtrace(cmd)
        output = `#{cmd} 2>&1`
        return if $?.success?

        raise Error, "rbtrace failed: #{output}"
      end

      def store_dump(temp_path, filename)
        File.open(temp_path) do |file|
          blob = ActiveStorage::Blob.create_and_upload!(
            io: file,
            filename: filename,
            content_type: "application/json",
            identify: false
          )
          
          puts "Heap dump stored with key: #{blob.key}"
          
          blob
        end
      end
  end
end
