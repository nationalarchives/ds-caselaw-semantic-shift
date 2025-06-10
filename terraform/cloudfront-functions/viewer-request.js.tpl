function basicAuth(request, userList) {
  var headers = request.headers;
  var authHeader = headers.authorization && headers.authorization.value;
  if (authHeader && authHeader.startsWith("Basic ")) {
    var encodedCreds = authHeader.split(' ')[1];
    var decoded = null;
    try {
      decoded = atob(encodedCreds);
    } catch (e) {}
    if (decoded) {
      var parts = decoded.split(':');
      if (parts.length === 2) {
        var username = parts[0];
        var password = parts[1];
        if (userList[username] === password) {
          return request;
        }
      }
    }
  }
  return {
    statusCode: 401,
    statusDescription: 'Unauthorized',
    headers: {
      'www-authenticate': {
        value: 'Basic realm="Restricted Area"'
      },
      'content-type': {
        value: 'text/html'
      }
    },
    body: '<html><body><h1>401 Unauthorized</h1><p>Access denied</p></body></html>'
  };
}
function handler(event) {
  var req = event.request;

  const userList = JSON.parse('${basic_auth_user_list}');
  req = basicAuth(req, userList)

  return req;
}
