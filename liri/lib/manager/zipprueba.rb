require 'zip'

def extract_zip(file, destination)

  FileUtils.mkdir_p(destination)

  Zip::File.open(File.expand_path(file)) do |zip_file|
    zip_file.each do |f|
      fpath = File.join(destination, f.name)
      FileUtils.mkdir_p(File.dirname(fpath))
      zip_file.extract(f, fpath) unless File.exist?(fpath)
    end
  end
end

extract_zip('/home/lesliie/Documentos/backup_tfg/liri.zip', '~liri')