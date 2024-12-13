from metacall import metacall_load_from_file, metacall_await
import json

# TODO: This test won't work because python port has no metacall_await
# implemented yet, this is a task to be done in metacall/core

metacall_load_from_file('node', ['./spacex.js'])
response = metacall_await('getSpaceXData')
print(json.dumps(response, indent=4))
