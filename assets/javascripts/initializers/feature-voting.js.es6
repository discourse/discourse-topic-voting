import ApplicationRoute from 'discourse/routes/application';

export default {
  name: 'feature-voting',
  initialize(){

    ApplicationRoute.reopen({
      actions: {
        vote() {
          alert("voted");
        },
        unvote() {
          alert("unvoted");
        }
      }
    })
  }
}