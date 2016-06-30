require './downloader'
TEMPLATE_NO = ARGV[0]
ColormeCrawler.new(ENV['COLORME_ID'], ENV['COLORME_PASSWORD']).restore_template(TEMPLATE_NO, repositry_path: '../colorme')
