enum GarmentCategory {
  top,
  bottom,
  outer,
  dress,
  shoes,
  bag,
  accessory;

  String get label {
    switch (this) {
      case GarmentCategory.top:
        return '상의';
      case GarmentCategory.bottom:
        return '하의';
      case GarmentCategory.outer:
        return '아우터';
      case GarmentCategory.dress:
        return '원피스';
      case GarmentCategory.shoes:
        return '신발';
      case GarmentCategory.bag:
        return '가방';
      case GarmentCategory.accessory:
        return '악세서리';
    }
  }
}

enum GarmentStatus { active, archived }

enum StyleTag {
  office,
  date,
  sport,
  travel,
  casual,
  formal;

  String get label {
    switch (this) {
      case StyleTag.office:
        return '오피스';
      case StyleTag.date:
        return '데이트';
      case StyleTag.sport:
        return '스포츠';
      case StyleTag.travel:
        return '여행';
      case StyleTag.casual:
        return '캐주얼';
      case StyleTag.formal:
        return '포멀';
    }
  }
}

enum Season {
  spring,
  summer,
  fall,
  winter;

  String get label {
    switch (this) {
      case Season.spring:
        return '봄';
      case Season.summer:
        return '여름';
      case Season.fall:
        return '가을';
      case Season.winter:
        return '겨울';
    }
  }
}

enum OutfitFeedback { like, dislike }

enum UnitSystem { metric, imperial }
