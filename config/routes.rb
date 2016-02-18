DiscourseFeatureVoting::Engine.routes.draw do
	post '/vote' => 'votes#add'
	post '/unvote' => 'votes#subtract'
end