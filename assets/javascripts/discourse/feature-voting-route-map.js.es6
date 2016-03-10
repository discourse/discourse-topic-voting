export default {
	resource: 'user',
	path: 'users/:username',
	map() {
		this.resource('userActivity', {path: 'activity'}, function(){
			this.route('votes')
		})
	}
};