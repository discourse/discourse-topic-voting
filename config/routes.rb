DiscourseFeatureVoting::Engine.routes.draw do
	post '/vote' => 'votes#add'
	post '/unvote' => 'votes#remove'
	post '/upgrade' => 'votes#upgrade'
	post '/downgrade' => 'votes#downgrade'
end