module Liri
  module Manager
    module Folder
      DIR_NAME = '.liri'
      DIR = File.join(Dir.pwd, '/', DIR_NAME)

      class << self
        # Create a folder calling DIR_NAME inside ruby project
        # In this folder will be compress ruby project and add all necessary configurations
        def create
          Dir.mkdir(DIR) unless Dir.exist?(DIR)
        end

        def delete
          FileUtils.rm_rf(dir) if Dir.exist?(DIR)
        end
      end
    end
  end
end