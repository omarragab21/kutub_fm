import 'package:flutter/material.dart';

import '../../domain/entities/active_reader.dart';

class ActiveUsersBar extends StatelessWidget {
  const ActiveUsersBar({
    super.key,
    required this.readers,
    required this.overflowCount,
  });

  final List<ActiveReader> readers;
  final int overflowCount;

  @override
  Widget build(BuildContext context) {
    final visibleReaders = readers.take(5).toList();

    return Row(
      children: [
        SizedBox(
          height: 48,
          width: (visibleReaders.length * 34) + (overflowCount > 0 ? 44 : 0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var index = 0; index < visibleReaders.length; index++)
                PositionedDirectional(
                  start: index * 34,
                  child: _ActiveReaderAvatar(reader: visibleReaders[index]),
                ),
              if (overflowCount > 0)
                PositionedDirectional(
                  start: visibleReaders.length * 34,
                  child: _OverflowAvatar(count: overflowCount),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'القراء النشطون',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'حضور حيّ يشارك الاقتباسات والمراجعات والأسئلة الآن.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.62),
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActiveReaderAvatar extends StatelessWidget {
  const _ActiveReaderAvatar({required this.reader});

  final ActiveReader reader;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF17130E),
            border: Border.all(
              color: const Color(0xFFD9AF68).withValues(alpha: 0.45),
            ),
          ),
          child: CircleAvatar(
            backgroundImage: NetworkImage(reader.avatarUrl),
            backgroundColor: const Color(0xFF2A2118),
          ),
        ),
        if (reader.isOnline)
          PositionedDirectional(
            end: 1,
            bottom: 1,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF5FD37C),
                border: Border.all(color: const Color(0xFF090806), width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

class _OverflowAvatar extends StatelessWidget {
  const _OverflowAvatar({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1A1510),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        '+$count',
        style: const TextStyle(
          color: Color(0xFFD9AF68),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
