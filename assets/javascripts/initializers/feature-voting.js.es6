import { withPluginApi } from 'discourse/lib/plugin-api';
import TopicRoute from 'discourse/routes/topic';
import TopicController from 'discourse/controllers/topic';
import { createWidget } from 'discourse/widgets/widget';
import { h } from 'virtual-dom';

function  startVoting(api){

}

export default {
  name: 'feature-voting',
  initialize: function() {
    withPluginApi('0.1', api => startVoting(api));
  }
}