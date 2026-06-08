// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'cici_design_tokens.dart';

class CiciNoteCard extends StatelessWidget {
  final String title;
  final String? description;
  final String? date;
  final VoidCallback? onTap;

  const CiciNoteCard({
    super.key,
    required this.title,
    this.description,
    this.date,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: CiciDesignTokens.getColor(
                context,
                CiciDesignTokens.border,
                CiciDesignTokens.darkBorder,
              ),
              width: 1,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: SvgPicture.asset(
                'assets/svg/document.svg',
                width: 18,
                height: 18,
              ),
            ),
            const SizedBox(width: CiciDesignTokens.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: CiciDesignTokens.fontSizeBody,
                      fontWeight: CiciDesignTokens.fontWeightMedium,
                      color: CiciDesignTokens.getColor(
                        context,
                        CiciDesignTokens.text,
                        CiciDesignTokens.darkText,
                      ),
                    ),
                  ),
                  if (description != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        description!,
                        style: TextStyle(
                          fontSize: CiciDesignTokens.fontSizeCaption,
                          color: CiciDesignTokens.getColor(
                            context,
                            CiciDesignTokens.gray,
                            CiciDesignTokens.darkGray,
                          ),
                          height: 1.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                ],
              ),
            ),
            if (date != null)
              Text(
                date!,
                style: TextStyle(
                  fontSize: CiciDesignTokens.fontSizeCaption,
                  color: CiciDesignTokens.getColor(
                    context,
                    CiciDesignTokens.gray,
                    CiciDesignTokens.darkGray,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CiciNoteCardList extends StatelessWidget {
  final List<CiciNoteCardData> notes;

  const CiciNoteCardList({super.key, required this.notes});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CiciDesignTokens.spaceMd,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: CiciDesignTokens.getColor(
          context,
          CiciDesignTokens.pageBg,
          CiciDesignTokens.darkPageBg,
        ),
        borderRadius: BorderRadius.circular(CiciDesignTokens.radiusSm),
      ),
      child: Column(
        children: notes.map((note) {
          return CiciNoteCard(
            title: note.title,
            description: note.description,
            date: note.date,
            onTap: note.onTap,
          );
        }).toList(),
      ),
    );
  }
}

class CiciNoteCardData {
  final String title;
  final String? description;
  final String? date;
  final VoidCallback? onTap;

  const CiciNoteCardData({
    required this.title,
    this.description,
    this.date,
    this.onTap,
  });
}
