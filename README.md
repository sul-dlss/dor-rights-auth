[![CircleCI](https://dl.circleci.com/status-badge/img/gh/sul-dlss/dor-rights-auth/tree/main.svg?style=svg)](https://dl.circleci.com/status-badge/redirect/gh/sul-dlss/dor-rights-auth/tree/main)
[![Maintainability](https://api.codeclimate.com/v1/badges/3f657524aa5f8937ebea/maintainability)](https://codeclimate.com/github/sul-dlss/dor-rights-auth/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/3f657524aa5f8937ebea/test_coverage)](https://codeclimate.com/github/sul-dlss/dor-rights-auth/test_coverage)
[![Gem Version](https://badge.fury.io/rb/dor-rights-auth.svg)](https://badge.fury.io/rb/dor-rights-auth)

## DOR Rights Auth

Creates objects with the following structure after parsing rightsMetadata XML

```ruby
# Rights for an object or File
class EntityRights
  @world = Rights
  @group {
    :stanford => Rights
  }
  @agent {
    'app1' => Rights,
    'app2' => Rights
  }
  @location {
    :spec => Rights
  }
end

# Rights for the entire object, and all files
# This is the object used by apps (stacks and purl)
class Dor::RightsAuth
  @object_level = EntityRights
  @file {
    'file1' => EntityRights,
    'file2' => EntityRights
  }
end
```
