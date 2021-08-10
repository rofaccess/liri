=begin
  Esta clase se encarga de comprimir y descomprimir archivos
=end
require 'zip'

module Liri
  module Common
    module Compressor
      class Zip
        # Inicializa la carpeta a comprimir y la ubicación en donde se guardará el archivo comprimido
        def initialize(input_dir, output_file)
          @input_dir = input_dir
          @output_file = output_file
        end

        # Comprime el directorio de entrada @input_dir en un archivo con extensión zip.
        def compress
          clear_output_file
          liri_setup = Liri::Manager::Setup.new
          liri_setup.create unless File.exist?(liri_setup.path)
          liri_setup.update_value_one_level('path_compress_file', @output_file)
          entries = Dir.entries(@input_dir) - %w[. ..]

          ::Zip::File.open(@output_file, ::Zip::File::CREATE) do |zipfile|
            write_entries(entries, '', zipfile)
          end
          true
        end

        def decompress(zip_dir, dir_destination)
          FileUtils.mkdir_p(dir_destination)
          ::Zip::File.open(File.expand_path(zip_dir)) do |zip_file|
            zip_file.each do |f|
              fpath = File.join(dir_destination, f.name)
              FileUtils.mkdir_p(File.dirname(fpath))
              zip_file.extract(f, fpath) unless File.exist?(fpath)
            end
          end
        end

        private

        def clear_output_file
          File.delete(@output_file) if File.exist?(@output_file)
        end

        # Un método de ayuda que hace que la recursión funcione
        def write_entries(entries, path, zipfile)
          entries.each do |e|
            zipfile_path = path == '' ? e : File.join(path, e)
            disk_file_path = File.join(@input_dir, zipfile_path)

            if File.directory? disk_file_path
              recursively_deflate_directory(disk_file_path, zipfile, zipfile_path)
            else
              put_into_archive(disk_file_path, zipfile, zipfile_path)
            end
          end
        end

        def recursively_deflate_directory(disk_file_path, zipfile, zipfile_path)
          zipfile.mkdir(zipfile_path)
          subdir = Dir.entries(disk_file_path) - %w[. ..]
          write_entries(subdir, zipfile_path, zipfile)
        end

        def put_into_archive(disk_file_path, zipfile, zipfile_path)
          zipfile.add(zipfile_path, disk_file_path)
        end
      end
    end
  end
end