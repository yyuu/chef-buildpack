# buildpack

Chef LWRP to build applications with using [buildpacks](https://devcenter.heroku.com/articles/buildpacks).

## Supported Platforms

* Debian GNU/Linux
* Ubuntu Linux

## Examples

Run `detect` and `compile` against `/var/www/my_app_name`.

```rb
buildpack_build "my_app_name" do
  buildpack_url "https://github.com/heroku/heroku-buildpack-ruby.git"
  build_dir "/var/www/my_app_name"
  cache_dir "/var/cache/my_app_name"
  env_dir "/var/lib/my_app_name"
end
```

## License and Authors

Copyright 2015 Yamashita, Yuu (yuu@treasure-data.com)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
