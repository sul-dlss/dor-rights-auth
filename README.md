[![Build Status](https://travis-ci.org/sul-dlss/dor-rights-auth.svg?branch=master)](https://travis-ci.org/sul-dlss/dor-rights-auth)
[![Dependency Status](https://gemnasium.com/sul-dlss/dor-rights-auth.svg)](https://gemnasium.com/sul-dlss/dor-rights-auth)

## DOR Rights Auth

Creates objects with the following structure after parsing rightsMetadata XML

```ruby
# Rights for an object or File
class EntityRights
  @world = #Rights
  @group {
    :stanford => #Rights
  }
  @agent {
    'app1' => #Rights,
    'app2' => #Rights
  }
end

# Rights for the entire object, and all files
# This is the object used by apps (stacks and purl)
class Dor::RightsAuth
  @object_level = # EntityRights
  @file {
    'file1' => EntityRights,
    'file2' => EntityRights
  }
end
```
