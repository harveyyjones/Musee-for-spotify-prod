// Model class for token response
class SpotifyTokenResponse {
  final String accessToken;
  final String tokenType;
  final int expiresIn;
  final String? refreshToken;
  final String scope;

  SpotifyTokenResponse({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    this.refreshToken,
    required this.scope,
  });

  factory SpotifyTokenResponse.fromJson(Map<String, dynamic> json) {
    return SpotifyTokenResponse(
      accessToken: json['access_token'],
      tokenType: json['token_type'],
      expiresIn: json['expires_in'],
      refreshToken: json['refresh_token'],
      scope: json['scope'],
    );
  }
}
