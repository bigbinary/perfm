module Perfm
  module Storage
    class Base
      def store(metrics)
        raise NotImplementedError
      end
    end
  end
end
