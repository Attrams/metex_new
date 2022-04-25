import Config

DotenvParser.load_file(".env")
config(:metex_new, openweather_api_key: System.get_env("OPENWEATHER_API_KEY"))
