String accessToken = "";

const Map<String, dynamic> categories = {
  "categories": {
    "creative_pursuits": {
      "name": "🎨 Creative Pursuits",
      "interests": [
        {"name": "🎸 Guitar", "type": "instrument"},
        {"name": "🎹 Piano", "type": "instrument"},
        {"name": "🎨 Painting", "type": "art"},
        {"name": "📷 Photography", "type": "art"},
        {"name": "✍️ Creative Writing", "type": "art"},
        {"name": "🎭 Theater", "type": "performing_arts"},
        {"name": "🎻 Violin", "type": "instrument"},
        {"name": "🎼 Music Production", "type": "art"},
        {"name": "🖌️ Digital Art", "type": "art"},
        {"name": "🎪 Circus Arts", "type": "performing_arts"}
      ]
    },
    "outdoor_activities": {
      "name": "🏃‍♂️ Outdoor Activities",
      "interests": [
        {"name": "🏃‍♂️ Running", "type": "sport"},
        {"name": "🏊‍♂️ Swimming", "type": "sport"},
        {"name": "🚴‍♂️ Cycling", "type": "sport"},
        {"name": "🏂 Snowboarding", "type": "sport"},
        {"name": "🧗‍♂️ Rock Climbing", "type": "adventure"},
        {"name": "🏕️ Camping", "type": "adventure"},
        {"name": "🌿 Hiking", "type": "adventure"},
        {"name": "🎣 Fishing", "type": "hobby"},
        {"name": "🏄‍♂️ Surfing", "type": "sport"},
        {"name": "🌺 Gardening", "type": "hobby"}
      ]
    },
    "intellectual_pursuits": {
      "name": "🧠 Intellectual Pursuits",
      "interests": [
        {"name": "📚 Reading", "type": "hobby"},
        {"name": "🎲 Chess", "type": "game"},
        {"name": "🧩 Puzzles", "type": "game"},
        {"name": "🌍 Language Learning", "type": "education"},
        {"name": "🔬 Science", "type": "education"},
        {"name": "💻 Programming", "type": "technology"},
        {"name": "🎓 Philosophy", "type": "education"},
        {"name": "📊 Data Science", "type": "technology"},
        {"name": "🎯 Strategy Games", "type": "game"},
        {"name": "🗣️ Debate", "type": "education"}
      ]
    },
    "lifestyle": {
      "name": "🌟 Lifestyle",
      "interests": [
        {"name": "🧘‍♂️ Meditation", "type": "wellness"},
        {"name": "🍳 Cooking", "type": "hobby"},
        {"name": "✈️ Traveling", "type": "adventure"},
        {"name": "🍷 Wine Tasting", "type": "hobby"},
        {"name": "🎬 Film", "type": "entertainment"},
        {"name": "🐕 Pet Care", "type": "lifestyle"},
        {"name": "🛍️ Fashion", "type": "lifestyle"},
        {"name": "🎮 Gaming", "type": "entertainment"},
        {"name": "🎪 Events & Festivals", "type": "entertainment"},
        {"name": "🌱 Sustainability", "type": "lifestyle"}
      ]
    }
  }
};
