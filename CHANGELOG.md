# Changelog

## [0.11.0](https://github.com/noir-lang/noir_bigcurve/compare/v0.10.0...v0.11.0) (2025-08-14)


### ⚠ BREAKING CHANGES

* bump to use `bignum` v0.8.0 ([#93](https://github.com/noir-lang/noir_bigcurve/issues/93))

### Miscellaneous Chores

* Bump to use `bignum` v0.8.0 ([#93](https://github.com/noir-lang/noir_bigcurve/issues/93)) ([2965d8b](https://github.com/noir-lang/noir_bigcurve/commit/2965d8b9e3d7ed30fb91747dbb4f57ee39b385d0))

## [0.10.0](https://github.com/noir-lang/noir_bigcurve/compare/v0.9.0...v0.10.0) (2025-07-28)


### ⚠ BREAKING CHANGES

* bump bignum to 0.7.4 ([#88](https://github.com/noir-lang/noir_bigcurve/issues/88))
* make `derive_curve_impl` public ([#82](https://github.com/noir-lang/noir_bigcurve/issues/82))
* remove some methods from `BigCurveTrait` ([#69](https://github.com/noir-lang/noir_bigcurve/issues/69))
* create separate `BigCurveTrait` implementations for each curve ([#65](https://github.com/noir-lang/noir_bigcurve/issues/65))

### Features

* Add benchmarks ([#87](https://github.com/noir-lang/noir_bigcurve/issues/87)) ([54de613](https://github.com/noir-lang/noir_bigcurve/commit/54de613621018cd5e775b8a899c7e40013cda3f7))
* Create separate `BigCurveTrait` implementations for each curve ([#65](https://github.com/noir-lang/noir_bigcurve/issues/65)) ([7cff316](https://github.com/noir-lang/noir_bigcurve/commit/7cff31643c621e272ffe93a54beda8f5cc105f43))
* Make `derive_curve_impl` public ([#82](https://github.com/noir-lang/noir_bigcurve/issues/82)) ([4cfe4f6](https://github.com/noir-lang/noir_bigcurve/commit/4cfe4f6a69aee11775a33fc21d61487e8cdb5cc8))
* Remove conditional select ([#74](https://github.com/noir-lang/noir_bigcurve/issues/74)) ([31ae850](https://github.com/noir-lang/noir_bigcurve/commit/31ae8508547eed12ecc2a614d7cdbcb147458072))
* Remove CurveParamsTrait ([#73](https://github.com/noir-lang/noir_bigcurve/issues/73)) ([59bde3b](https://github.com/noir-lang/noir_bigcurve/commit/59bde3b603c859920f9d99b20bc44793a52d49cb))
* Remove Trait suffix from BigCurveTrait ([#71](https://github.com/noir-lang/noir_bigcurve/issues/71)) ([4aed759](https://github.com/noir-lang/noir_bigcurve/commit/4aed759b843815af915d91bb2252bed6debdae9c))
* Use to_le_bytes and bitwise operations to replace to_le_radix ([#75](https://github.com/noir-lang/noir_bigcurve/issues/75)) ([6adb77c](https://github.com/noir-lang/noir_bigcurve/commit/6adb77cdd13805f0b3d1fff6b4747fbdfa2dde75))


### Bug Fixes

* Avoid using private export of `ScalarField` in macro ([#89](https://github.com/noir-lang/noir_bigcurve/issues/89)) ([200362a](https://github.com/noir-lang/noir_bigcurve/commit/200362a8679758e0c634fdd3b3b8b9af9bb02a07))
* Bump bignum v0.7.5 ([#91](https://github.com/noir-lang/noir_bigcurve/issues/91)) ([8390174](https://github.com/noir-lang/noir_bigcurve/commit/83901749ee0c9073bef2c03f4eaa31580dda7e6f))


### Miscellaneous Chores

* Bump bignum to 0.7.4 ([#88](https://github.com/noir-lang/noir_bigcurve/issues/88)) ([2dca59a](https://github.com/noir-lang/noir_bigcurve/commit/2dca59a57aa13c5f4f796564d077106cbf9d3c9a))
* Remove some methods from `BigCurveTrait` ([#69](https://github.com/noir-lang/noir_bigcurve/issues/69)) ([832fabc](https://github.com/noir-lang/noir_bigcurve/commit/832fabc210cafcdbbb1e0fa4dc4327f1bf0aaf99))

## [0.9.0](https://github.com/noir-lang/noir_bigcurve/compare/v0.8.0...v0.9.0) (2025-06-06)


### ⚠ BREAKING CHANGES

* bump bignum version to 0.7.3 ([#49](https://github.com/noir-lang/noir_bigcurve/issues/49))
* bump bignum to 0.7.2 ([#47](https://github.com/noir-lang/noir_bigcurve/issues/47))

### Features

* Bump bignum to 0.7.2 ([#47](https://github.com/noir-lang/noir_bigcurve/issues/47)) ([1eaae46](https://github.com/noir-lang/noir_bigcurve/commit/1eaae46ca270a340f57399232e3710730632c03e))


### Bug Fixes

* Don't cast numbers to bool ([#51](https://github.com/noir-lang/noir_bigcurve/issues/51)) ([349c60b](https://github.com/noir-lang/noir_bigcurve/commit/349c60b77b7f769af73271036f2dd27eae78ae36))
* Make necessary items public ([#54](https://github.com/noir-lang/noir_bigcurve/issues/54)) ([de513bb](https://github.com/noir-lang/noir_bigcurve/commit/de513bbb2ebc6158d565b49b6f127a95fda7388c))


### Miscellaneous Chores

* Bump bignum version to 0.7.3 ([#49](https://github.com/noir-lang/noir_bigcurve/issues/49)) ([4d48ebf](https://github.com/noir-lang/noir_bigcurve/commit/4d48ebfb36c4681463eb67dbae807ecab413a094))

## [0.8.0](https://github.com/noir-lang/noir_bigcurve/compare/v0.7.0...v0.8.0) (2025-05-16)


### ⚠ BREAKING CHANGES

* bump to bignum v0.7.1 ([#46](https://github.com/noir-lang/noir_bigcurve/issues/46))

### Features

* Bump to bignum v0.7.1 ([#46](https://github.com/noir-lang/noir_bigcurve/issues/46)) ([c0b3997](https://github.com/noir-lang/noir_bigcurve/commit/c0b3997f986a0724fa14cfe4645c376a8e84a243))


### Bug Fixes

* Update to use poseidon library ([#44](https://github.com/noir-lang/noir_bigcurve/issues/44)) ([b12d659](https://github.com/noir-lang/noir_bigcurve/commit/b12d6594c650f08829463251c6c0064dc9a955c6))

## [0.7.0](https://github.com/noir-lang/noir_bigcurve/compare/v0.6.0...v0.7.0) (2025-02-25)


### ⚠ BREAKING CHANGES

* bump bignum version to `v0.6.0` ([#40](https://github.com/noir-lang/noir_bigcurve/issues/40))

### Miscellaneous Chores

* Bump bignum version to `v0.6.0` ([#40](https://github.com/noir-lang/noir_bigcurve/issues/40)) ([630ca96](https://github.com/noir-lang/noir_bigcurve/commit/630ca96be2eaf2ace1e087cf5bd251b86d2800bc))

## [0.6.0](https://github.com/noir-lang/noir_bigcurve/compare/v0.5.2...v0.6.0) (2025-02-09)


### ⚠ BREAKING CHANGES

* bump bignum to `v0.5.0` ([#30](https://github.com/noir-lang/noir_bigcurve/issues/30))

### Features

* Bump bignum to `v0.5.0` ([#30](https://github.com/noir-lang/noir_bigcurve/issues/30)) ([8b88fb7](https://github.com/noir-lang/noir_bigcurve/commit/8b88fb7bc2092ca51fedcddd31ee225d6ea971a8))

## [0.5.2](https://github.com/noir-lang/noir_bigcurve/compare/v0.5.1...v0.5.2) (2024-12-21)


### Bug Fixes

* Update format strings to use new format ([#22](https://github.com/noir-lang/noir_bigcurve/issues/22)) ([b8bd97c](https://github.com/noir-lang/noir_bigcurve/commit/b8bd97c7510e9ea7303c8e8c16719dbb42374596))

## [0.5.1](https://github.com/noir-lang/noir_bigcurve/compare/v0.5.0...v0.5.1) (2024-11-30)


### Bug Fixes

* Update Tests ([#13](https://github.com/noir-lang/noir_bigcurve/issues/13)) ([e1f1c9c](https://github.com/noir-lang/noir_bigcurve/commit/e1f1c9c985c29213b17d965266e4f30a67b59766))

## [0.5.0](https://github.com/noir-lang/noir_bigcurve/compare/v0.3.1...v0.5.0) (2024-11-08)


### ⚠ BREAKING CHANGES

* update to noir_bignum v0.4.0 ([#10](https://github.com/noir-lang/noir_bigcurve/issues/10))

### Features

* Added predefined curves ([#8](https://github.com/noir-lang/noir_bigcurve/issues/8)) ([582dc80](https://github.com/noir-lang/noir_bigcurve/commit/582dc808886d146d40aee334bbc200ee858ad747))
* Update to noir_bignum v0.4.0 ([#10](https://github.com/noir-lang/noir_bigcurve/issues/10)) ([3930699](https://github.com/noir-lang/noir_bigcurve/commit/3930699251c55ebc45881536723a44faa3fd15ed))
