require './downloader'
ColormeCrawler.new(ENV['COLORME_ID'], ENV['COLORME_PASSWORD']).restore_template(6, repositry_path: '../colorme')
