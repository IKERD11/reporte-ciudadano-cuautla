import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:reporte_ciudadano/core/citizen_design.dart';

Widget frame(Widget child, {bool reduced = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduced),
    child: Scaffold(body: Center(child: child)),
  ),
);
void main() {
  testWidgets('CSS hover follows ease at 80ms and reaches -2px at 160ms', (
    tester,
  ) async {
    const key = ValueKey('card');
    await tester.pumpWidget(
      frame(
        const DesignInteraction(
          child: SizedBox(key: key, width: 100, height: 80),
        ),
      ),
    );
    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await pointer.addPointer(location: const Offset(0, 0));
    await pointer.moveTo(tester.getCenter(find.byKey(key)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final container = find
        .descendant(
          of: find.byType(DesignInteraction),
          matching: find.byType(Container),
        )
        .first;
    double offset() =>
        tester.widget<Container>(container).transform!.storage[13];
    expect(offset(), closeTo(-2 * Curves.ease.transform(.5), .02));
    await tester.pump(const Duration(milliseconds: 80));
    expect(offset(), closeTo(-2, .01));
    await pointer.removePointer();
  });

  testWidgets(
    'buttons brighten on hover and move one pixel only while pressed',
    (tester) async {
      await tester.pumpWidget(
        frame(DesignButton('Continuar', onPressed: () {})),
      );
      final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await pointer.addPointer(location: const Offset(0, 0));
      await pointer.moveTo(tester.getCenter(find.text('Continuar')));
      await tester.pump();
      expect(find.byType(ColorFiltered), findsOneWidget);
      final target = find
          .descendant(
            of: find.byType(AnimatedContainer).first,
            matching: find.byType(Container),
          )
          .first;
      await pointer.down(tester.getCenter(find.text('Continuar')));
      await tester.pump();
      expect(tester.widget<Container>(target).transform!.storage[13], 1);
      await pointer.up();
      await tester.pump();
      expect(tester.widget<Container>(target).transform!.storage[13], 0);
      await pointer.removePointer();
      await tester.pumpWidget(
        frame(const DesignButton('Continuar', onPressed: null)),
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(
        location: tester.getCenter(find.text('Continuar')),
      );
      await tester.pump();
      expect(find.byType(ColorFiltered), findsNothing);
      await mouse.removePointer();
    },
  );

  testWidgets(
    'password eye crossfades for 180ms and finishes spring at 220ms',
    (tester) async {
      await tester.pumpWidget(frame(const DesignPasswordEye(visible: false)));
      await tester.pumpWidget(frame(const DesignPasswordEye(visible: true)));
      await tester.pump(const Duration(milliseconds: 90));
      final open = find.byKey(const ValueKey('eye-open'));
      final opacity = find
          .descendant(of: open, matching: find.byType(FadeTransition))
          .first;
      expect(
        tester.widget<FadeTransition>(opacity).opacity.value,
        closeTo(Curves.ease.transform(.5), .02),
      );
      await tester.pump(const Duration(milliseconds: 130));
      expect(tester.widget<FadeTransition>(opacity).opacity.value, 1);
      final scale = find
          .descendant(of: open, matching: find.byType(Transform))
          .last;
      expect(
        tester.widget<Transform>(scale).transform.storage[0],
        closeTo(1, .001),
      );
    },
  );

  testWidgets('zone panel starts 22px down; reduced motion skips entrance', (
    tester,
  ) async {
    final progress = AnimationController.unbounded(vsync: tester, value: 0);
    await tester.pumpWidget(
      frame(
        DesignPanelEntrance(
          animation: progress,
          child: const SizedBox(width: 100, height: 100),
        ),
      ),
    );
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0);
    expect(
      tester
          .widget<Transform>(
            find
                .descendant(
                  of: find.byType(DesignPanelEntrance),
                  matching: find.byType(Transform),
                )
                .first,
          )
          .transform
          .storage[13],
      22,
    );
    progress.value = .5;
    await tester.pump();
    expect(
      tester.widget<Opacity>(find.byType(Opacity)).opacity,
      closeTo(Curves.easeOut.transform(.5), .001),
    );
    await tester.pumpWidget(
      frame(
        DesignPanelEntrance(animation: progress, child: const SizedBox()),
        reduced: true,
      ),
    );
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
    expect(
      tester
          .widget<Transform>(
            find
                .descendant(
                  of: find.byType(DesignPanelEntrance),
                  matching: find.byType(Transform),
                )
                .first,
          )
          .transform
          .storage[13],
      0,
    );
    await tester.pumpWidget(
      frame(const DesignPasswordEye(visible: false), reduced: true),
    );
    await tester.pumpWidget(
      frame(const DesignPasswordEye(visible: true), reduced: true),
    );
    await tester.pump();
    for (final opacity in tester.widgetList<AnimatedOpacity>(
      find.byType(AnimatedOpacity),
    )) {
      expect(opacity.duration, Duration.zero);
    }
    await tester.pumpWidget(const SizedBox());
    progress.dispose();
  });
  testWidgets('toast enters 8px over 180ms and reduced motion is immediate', (
    tester,
  ) async {
    await tester.pumpWidget(frame(const DesignToast('Aviso de prueba')));
    final opacity = find.descendant(
      of: find.byType(DesignToast),
      matching: find.byType(Opacity),
    );
    final transform = find.descendant(
      of: find.byType(DesignToast),
      matching: find.byType(Transform),
    );
    expect(tester.widget<Opacity>(opacity).opacity, 0);
    expect(tester.widget<Transform>(transform).transform.storage[13], 8);
    await tester.pump(const Duration(milliseconds: 90));
    expect(
      tester.widget<Opacity>(opacity).opacity,
      closeTo(Curves.easeOut.transform(.5), .001),
    );
    await tester.pump(const Duration(milliseconds: 90));
    expect(tester.widget<Opacity>(opacity).opacity, 1);
    await tester.pumpWidget(
      frame(
        const DesignToast('Aviso nuevo', key: ValueKey('new')),
        reduced: true,
      ),
    );
    await tester.pump();
    expect(tester.widget<Opacity>(opacity).opacity, 1);
    expect(tester.widget<Transform>(transform).transform.storage[13], 0);
  });
  testWidgets(
    'original SVG preserves its requested size inside a larger control',
    (tester) async {
      await tester.pumpWidget(
        frame(
          const SizedBox(
            width: 49,
            height: 49,
            child: CitizenIcon('user', size: 27),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(SvgPicture)), const Size(27, 27));
      expect(tester.takeException(), isNull);
    },
  );
}
