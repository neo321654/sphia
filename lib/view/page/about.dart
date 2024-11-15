import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide LicensePage;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:sphia/view/page/license.dart';
import 'package:url_launcher/url_launcher.dart';

const sphiaVersion = '1.0.2';
const sphiaBuildNumber = 15;
const sphiaFullVersion = '$sphiaVersion+$sphiaBuildNumber';
const sphiaLastCommitHash = 'SELF_BUILD';

class SlideAboutPage extends HookWidget {
  const SlideAboutPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 150),
    );

    final showLeftPage = useState(true);

    void switchPage() {
      if (showLeftPage.value) {
        animationController.forward();
      } else {
        animationController.reverse();
      }
      showLeftPage.value = !showLeftPage.value;
    }

    return Scaffold(
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: animationController,
            builder: (context, child) {
              return Stack(
                children: [
                  const Positioned.fill(
                    child: AboutPage(),
                  ),
                  Positioned.fill(
                    child: Transform.translate(
                      offset: Offset(
                        MediaQuery.of(context).size.width *
                            (1 - animationController.value),
                        0,
                      ),
                      child: const PackagesPage(),
                    ),
                  ),
                ],
              );
            },
          ),
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: showLeftPage.value ? switchPage : null,
              child: Container(
                color: Colors.transparent,
                child: showLeftPage.value
                    ? const Center(
                        child: Icon(Symbols.chevron_left),
                      )
                    : null,
              ),
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            child: GestureDetector(
              onTap: showLeftPage.value ? null : switchPage,
              child: Container(
                color: Colors.transparent,
                child: !showLeftPage.value
                    ? const Center(
                        child: Icon(Symbols.chevron_right),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo_about.png',
              width: 256.0,
              height: 256.0,
            ),
            const SizedBox(width: 32.0),
            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // about - Sphia
                Flexible(
                  child: Text(
                    'Sphia',
                    style: TextStyle(fontSize: 48),
                  ),
                ),
                SizedBox(height: 16.0),
                // about - version
                Text(
                  'Version: $sphiaVersion',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                // about - build number
                Text(
                  'Build Number: $sphiaBuildNumber',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                // about - last commit
                Text(
                  'Last Commit: $sphiaLastCommitHash',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                SizedBox(height: 16.0),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PackagesPage extends StatelessWidget {
  const PackagesPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        child: Stack(
          children: [
            Theme(
              data: Theme.of(context).copyWith(
                highlightColor: Colors.transparent,
                splashColor: Colors.transparent,
                appBarTheme: const AppBarTheme(
                  scrolledUnderElevation: 0,
                  titleTextStyle: TextStyle(color: Colors.transparent),
                ),
                scaffoldBackgroundColor: Colors.transparent,
                cardColor: Theme.of(context).colorScheme.surface,
                cardTheme: const CardTheme(
                  shadowColor: Colors.transparent,
                ),
                listTileTheme: const ListTileThemeData(
                  tileColor: Colors.transparent,
                  selectedTileColor: Colors.transparent,
                ),
              ),
              child: const ClipRect(
                child: LicensePage(),
              ),
            ),
            const Positioned(
              top: -8,
              left: 0,
              child: SphiaCard(),
            ),
          ],
        ),
      ),
    );
  }
}

class SphiaCard extends StatelessWidget {
  const SphiaCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Image.asset(
          'assets/logo_about.png',
          width: 144.0,
          height: 144.0,
        ),
        Flexible(
          fit: FlexFit.loose,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sphia',
                style: TextStyle(fontSize: 36),
              ),
              const SizedBox(height: 8.0),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Github',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.blue,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () async {
                                await launchUrl(
                                  Uri.parse(
                                    'https://github.com/YukidouSatoru/sphia',
                                  ),
                                );
                              },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Row(
                      children: [
                        const Text(
                          'GPL-3.0 ',
                          style: TextStyle(fontSize: 16),
                        ),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'License',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.blue,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () async {
                                    await launchUrl(
                                      Uri.parse(
                                        'https://www.gnu.org/licenses/gpl-3.0.en.html',
                                      ),
                                    );
                                  },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2.0),
                    const Text(
                      'Powered by Flutter',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
