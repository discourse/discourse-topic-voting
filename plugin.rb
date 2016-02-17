# name: discourse-feature-voting
# about: Adds the ability to vote on features in a specified category.
# version: 0.1
# author: Joe Buhlig joebuhlig.com
# url: https://www.github.com/joebuhlig/discourse-feature-voting

register_asset "stylesheets/feature-voting.scss"
register_asset "javascripts/feature-voting.js"

enabled_site_setting :feature_voting_enabled

# load the engine
load File.expand_path('../lib/discourse_feature_voting/engine.rb', __FILE__)

after_initialize do


	Discourse::Application.routes.append do
		mount ::DiscourseFeatureVoting::Engine, at: "/vote"
	end
end