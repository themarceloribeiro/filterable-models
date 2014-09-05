require "filterable-models/version"
require "filterable-models/base"
require "filterable-models/helper"

ActiveRecord::Base.send :include, Filterable::Models::Base
ActionView::Helpers::FormTagHelper.send :include, Filterable::Models::Helper
ActionView::Base.send :include, Filterable::Models::Helper