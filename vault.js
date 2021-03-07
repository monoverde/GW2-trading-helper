'use strict';

const e = React.createElement;

class LikeButton extends React.Component {
  constructor(props) {
    super(props);
    this.state = { liked: false };
  }

  render() {
    e(
      'button',
      {onClick : {this.text = 'Fred'}},
      'Like'
    );
  }
}

const domContainer = document.getElementById('test-out');

ReactDOM.render(e(LikeButton), domContainer);