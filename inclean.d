/*
    This file is part of the Inclean distribution.

    https://github.com/senselogic/INCLEAN

    Copyright (C) 2017 Eric Pelzer (ecstatic.coder@gmail.com)

    Inclean is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, version 3.

    Inclean is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Inclean.  If not, see <http://www.gnu.org/licenses/>.
*/

// == LOCAL

// -- IMPORTS

import core.stdc.stdlib : exit;
import std.algorithm : countUntil;
import std.conv : to;
import std.file : dirEntries, readText, write, SpanMode, FileException;
import std.path : globMatch;
import std.stdio : writeln;
import std.string : endsWith, indexOf, join, lastIndexOf, replace, split, startsWith, strip, toUpper;

// -- TYPES

enum TOKEN_TYPE
{
    // -- CONSTANTS

    None,
    BeginShortComment,
    ShortComment,
    BeginLongComment,
    LongComment,
    EndLongComment,
    RegularExpressionLiteral,
    BeginCharacterLiteral,
    CharacterLiteral,
    EndCharacterLiteral,
    BeginStringLiteral,
    StringLiteral,
    EndStringLiteral,
    BeginTextLiteral,
    NumericLiteral,
    Identifier,
    Command,
    Parameter,
    Operator,
    Separator,
    Delimiter,
    Special
}

// ~~

class TOKEN
{
    // -- ATTRIBUTES

    TOKEN_TYPE
        Type;
    string
        Text;
    long
        LineIndex,
        ColumnIndex,
        PriorLineCount,
        PriorSpaceCount;
    bool
        StartsLine,
        EndsLine;

    // -- CONSTRUCTORS

    this(
        )
    {
        Type = TOKEN_TYPE.None;
    }

    // ~~

    this(
        TOKEN token
        )
    {
        Type = token.Type;
        Text = token.Text;
        LineIndex = token.LineIndex;
        ColumnIndex = token.ColumnIndex;
        PriorLineCount = token.PriorLineCount;
        PriorSpaceCount = token.PriorSpaceCount;
        StartsLine = token.StartsLine;
        EndsLine = token.EndsLine;
    }

    // ~~

    this(
        TOKEN_TYPE token_type,
        string text
        )
    {
        Type = token_type;
        Text = text;
    }

    // -- INQUIRIES

    bool IsTypeDeclaration(
        )
    {
        return
            Text == "class"
            || Text == "struct"
            || Text == "union"
            || Text == "enum";
    }

    // ~~

    bool IsTypeQualifier(
        )
    {
        return Text.endsWith( "DLL" );
    }

    // ~~

    void Dump(
        )
    {
        writeln(
            Type,
            ", `",
            Text,
            "` [",
            LineIndex,
            ", ",
            ColumnIndex,
            " | ",
            PriorLineCount,
            ", ",
            PriorSpaceCount,
            " ] ",
            StartsLine,
            " ",
            EndsLine
            );
    }
}

// ~~

class TYPE
{
    // -- ATTRIBUTES

    string
        Name,
        IncludedFilePath;

    // -- CONSTRUCTORS

    this(
        string name
        )
    {
        Name = name;
    }

    // ~~

    this(
        string name,
        string included_file_path
        )
    {
        Name = name;
        IncludedFilePath = included_file_path;
    }
}

// ~~

class CODE
{
    // -- ATTRIBUTES

    string
        FileText,
        FilePath,
        IncludedFilePath;
    long
        LineCharacterIndex,
        CharacterIndex,
        LineIndex,
        TokenCharacterIndex;
    TOKEN[]
        TokenArray;
    TOKEN
        Token;
    TOKEN_TYPE
        TokenType;
    long
        TokenIndex;
    bool
        TokenIsSplit;
    TYPE[ string ]
        DeclaredTypeMap,
        UsedTypeMap,
        MissingTypeMap,
        UnusedTypeMap;

    // -- OPERATIONS

    void AddToken()
    {
        Token = new TOKEN( TokenType, "" );
        Token.LineIndex = LineIndex;
        Token.ColumnIndex = TokenCharacterIndex - LineCharacterIndex;

        TokenArray ~= Token;
        TokenIsSplit = false;
    }

    // ~~

    void BeginToken(
        TOKEN_TYPE token_type
        )
    {
        Token = null;
        TokenType = token_type;
    }

    // ~~

    void AddTokenCharacter(
        char token_character
        )
    {
        if ( Token is null
             || TokenIsSplit )
        {
            AddToken();
        }

        Token.Text ~= token_character;
        ++TokenCharacterIndex;
    }

    // ~~

    void EndToken()
    {
        Token = null;
        TokenType = TOKEN_TYPE.None;
    }

    // ~~

    void SetPriorSpaceCount(
        )
    {
        long
            token_index;
        TOKEN
            prior_token,
            token;

        prior_token = null;

        for ( token_index = 0;
              token_index < TokenArray.length;
              ++token_index )
        {
            token = TokenArray[ token_index ];

            if ( token_index == 0 )
            {
                token.PriorLineCount = token.LineIndex;
            }
            else if ( token.LineIndex > prior_token.LineIndex )
            {
                token.PriorLineCount = token.LineIndex - prior_token.LineIndex;
            }

            if ( token_index == 0
                 || token.LineIndex > prior_token.LineIndex )
            {
                token.PriorSpaceCount = token.ColumnIndex;
            }
            else
            {
                token.PriorSpaceCount = token.ColumnIndex - prior_token.ColumnIndex - prior_token.Text.length;
            }

            if ( token_index == 0
                 || token.LineIndex > prior_token.LineIndex )
            {
                if ( prior_token !is null )
                {
                    prior_token.EndsLine = true;
                }

                token.StartsLine = true;
            }

            prior_token = token;
        }
    }

    // ~~

    void Set(
        string file_text,
        string file_path,
        string included_file_path
        )
    {
        char
            character,
            next_character,
            prior_character;
        long
            character_count;

        FileText = file_text.replace( "\t", "    " ).replace( "\r", "" );
        FilePath = file_path;
        IncludedFilePath = included_file_path;

        LineCharacterIndex = 0;
        LineIndex = 0;
        TokenArray = [];
        TokenIsSplit = false;

        EndToken();

        character_count = FileText.length;

        TokenCharacterIndex = 0;

        while ( TokenCharacterIndex < character_count )
        {
            prior_character = ( TokenCharacterIndex - 1 >= 0 ) ? FileText[ TokenCharacterIndex - 1 ] : 0;
            character = FileText[ TokenCharacterIndex ];
            next_character = ( TokenCharacterIndex + 1 < character_count ) ? FileText[ TokenCharacterIndex + 1 ] : 0;

            if ( character == '\n' )
            {
                if ( TokenType == TOKEN_TYPE.ShortComment
                     || TokenType == TOKEN_TYPE.CharacterLiteral
                     || TokenType == TOKEN_TYPE.StringLiteral )
                {
                    EndToken();
                }

                ++TokenCharacterIndex;
                TokenIsSplit = true;

                ++LineIndex;
                LineCharacterIndex = TokenCharacterIndex;
            }
            else if ( character == ' ' )
            {
                if ( TokenType == TOKEN_TYPE.ShortComment
                     || TokenType == TOKEN_TYPE.CharacterLiteral
                     || TokenType == TOKEN_TYPE.StringLiteral )
                {
                    AddTokenCharacter( character );
                }
                else
                {
                    ++TokenCharacterIndex;
                    TokenIsSplit = true;
                }
            }
            else if ( TokenType == TOKEN_TYPE.ShortComment )
            {
                AddTokenCharacter( character );
            }
            else if ( TokenType == TOKEN_TYPE.LongComment )
            {
                if ( character == '*'
                     && next_character == '/' )
                {
                    BeginToken( TOKEN_TYPE.EndLongComment );
                    AddTokenCharacter( character );
                    AddTokenCharacter( next_character );
                    EndToken();
                }
                else
                {
                    AddTokenCharacter( character );
                }
            }
            else if ( TokenType == TOKEN_TYPE.CharacterLiteral )
            {
                if ( character == '\'' )
                {
                    BeginToken( TOKEN_TYPE.EndCharacterLiteral );
                    AddTokenCharacter( character );
                    EndToken();
                }
                else if ( character == '\\' )
                {
                    AddTokenCharacter( character );
                    AddTokenCharacter( next_character );
                }
                else
                {
                    AddTokenCharacter( character );
                }
            }
            else if ( TokenType == TOKEN_TYPE.StringLiteral )
            {
                if ( character == '\"' )
                {
                    BeginToken( TOKEN_TYPE.EndStringLiteral );
                    AddTokenCharacter( character );
                    EndToken();
                }
                else if ( character == '\\' )
                {
                    AddTokenCharacter( character );
                    AddTokenCharacter( next_character );
                }
                else
                {
                    AddTokenCharacter( character );
                }
            }
            else if ( character == '/'
                      && next_character == '/' )
            {
                BeginToken( TOKEN_TYPE.BeginShortComment );
                AddTokenCharacter( character );
                AddTokenCharacter( next_character );
                EndToken();

                BeginToken( TOKEN_TYPE.ShortComment );
            }
            else if ( character == '/'
                      && next_character == '*' )
            {
                BeginToken( TOKEN_TYPE.BeginLongComment );
                AddTokenCharacter( character );
                AddTokenCharacter( next_character );
                EndToken();

                BeginToken( TOKEN_TYPE.LongComment );
            }
            else if ( character == '\'' )
            {
                BeginToken( TOKEN_TYPE.BeginCharacterLiteral );
                AddTokenCharacter( character );
                EndToken();

                BeginToken( TOKEN_TYPE.CharacterLiteral );
            }
            else if ( character == '\"' )
            {
                BeginToken( TOKEN_TYPE.BeginStringLiteral );
                AddTokenCharacter( character );
                EndToken();

                BeginToken( TOKEN_TYPE.StringLiteral );
            }
            else if ( IsNumberCharacter( character, prior_character, next_character )
                      && TokenType == TOKEN_TYPE.NumericLiteral )
            {
                AddTokenCharacter( character );
            }
            else if ( IsIdentifierCharacter( character )
                      && TokenType == TOKEN_TYPE.Identifier )
            {
                AddTokenCharacter( character );
            }
            else if ( character >= '0' && character <= '9' )
            {
                BeginToken( TOKEN_TYPE.NumericLiteral );
                AddTokenCharacter( character );
            }
            else if ( IsIdentifierCharacter( character )
                      || ( character == '#'
                           && next_character >= 'a'
                           && next_character <= 'z' ) )
            {
                BeginToken( TOKEN_TYPE.Identifier );
                AddTokenCharacter( character );
            }
            else if ( IsOperatorCharacter( character ) )
            {
                BeginToken( TOKEN_TYPE.Operator );
                AddTokenCharacter( character );
                EndToken();
            }
            else if ( character == ':'
                      && next_character == ':' )
            {
                BeginToken( TOKEN_TYPE.Operator );
                AddTokenCharacter( character );
                AddTokenCharacter( next_character );
                EndToken();
            }
            else if ( IsSeparatorCharacter( character ) )
            {
                BeginToken( TOKEN_TYPE.Separator );
                AddTokenCharacter( character );
                EndToken();
            }
            else if ( IsDelimiterCharacter( character ) )
            {
                BeginToken( TOKEN_TYPE.Delimiter );
                AddTokenCharacter( character );
                EndToken();
            }
            else
            {
                BeginToken( TOKEN_TYPE.Special );
                AddTokenCharacter( character );
                EndToken();
            }
        }

        SetPriorSpaceCount();
    }

    // ~~

    void AddDeclaredType(
        string type_name,
        string included_file_path = ""
        )
    {
        if ( DebugOptionIsEnabled )
        {
            if ( ( type_name in DeclaredTypeMap ) is null )
            {
                writeln( "    Declared type : ", type_name );
            }
        }

        DeclaredTypeMap[ type_name ] = new TYPE( type_name, included_file_path );
    }

    // ~~

    void AddDeclaredTypes(
        string included_file_path
        )
    {
        foreach ( type; TypeMap )
        {
            if ( type.IncludedFilePath == included_file_path )
            {
                AddDeclaredType( type.Name, type.IncludedFilePath );
            }
        }
    }

    // ~~

    void AddUsedType(
        string type_name
        )
    {
        if ( DebugOptionIsEnabled )
        {
            if ( ( type_name in UsedTypeMap ) is null )
            {
                writeln( "    Used type : ", type_name );
            }
        }

        UsedTypeMap[ type_name ] = new TYPE( type_name );
    }

    // ~~

    void AddMissingType(
        string type_name
        )
    {
        if ( VerboseOptionIsEnabled )
        {
            writeln( "    Missing type : ", type_name );
        }

        MissingTypeMap[ type_name ] = new TYPE( type_name );
    }

    // ~~

    void AddUnusedType(
        string type_name,
        string included_file_path
        )
    {
        if ( VerboseOptionIsEnabled )
        {
            writeln( "    Unused type : ", type_name, " (", included_file_path, ")" );
        }

        UnusedTypeMap[ type_name ] = new TYPE( type_name, included_file_path );
    }

    // ~~

    bool IsNameSpaceDeclaration(
        long token_index
        )
    {
        return
            token_index > 0
            && token_index + 1 < TokenArray.length
            && TokenArray[ token_index - 1 ].Text == "namespace"
            && TokenArray[ token_index + 1 ].Text == "{";
    }

    // ~~

    bool IsTypeDefinition(
        long token_index
        )
    {
        long
            brace_level,
            prior_token_index;
        TOKEN
            prior_token;

        for ( prior_token_index = token_index - 1;
              prior_token_index >= 0;
              --prior_token_index )
        {
            prior_token = TokenArray[ prior_token_index ];

            if ( prior_token.Type == TOKEN_TYPE.Identifier )
            {
                if ( prior_token.Text == "typedef"
                     && brace_level == 0 )
                {
                    return true;
                }
            }
            else if ( prior_token.Type == TOKEN_TYPE.Separator )
            {
                if ( prior_token.Text == ";"
                     && brace_level == 0 )
                {
                    return false;
                }
            }
            else if ( prior_token.Type == TOKEN_TYPE.Delimiter )
            {
                if ( prior_token.Text == "}" )
                {
                    if ( brace_level == 0
                         && prior_token_index != token_index - 1 )
                    {
                        return false;
                    }

                    ++brace_level;
                }
                else if ( prior_token.Text == "{" )
                {
                    --brace_level;

                    if ( brace_level < 0 )
                    {
                        return false;
                    }
                }
            }
        }

        return false;
    }

    // ~~

    bool IsTypeDeclaration(
        long token_index
        )
    {
        if ( token_index + 1 < TokenArray.length )
        {
            if ( TokenArray[ token_index + 1 ].Text == ";" )
            {
                return IsTypeDefinition( token_index );
            }
            else
            {
                return
                    ( token_index > 0
                      && TokenArray[ token_index - 1 ].IsTypeDeclaration() )
                    || ( token_index > 1
                         && TokenArray[ token_index - 2 ].IsTypeDeclaration()
                         && TokenArray[ token_index - 1 ].Text.indexOf( "DLL" ) >= 0 );
            }
        }
        else
        {
            return false;
        }
    }

    // ~~

    bool IsForwardTypeDeclaration(
        long token_index
        )
    {
        if ( token_index + 1 < TokenArray.length
             && TokenArray[ token_index + 1 ].Text == ";" )
        {
            return
                ( token_index > 0
                  && TokenArray[ token_index - 1 ].IsTypeDeclaration() )
                || ( token_index > 1
                     && TokenArray[ token_index - 2 ].IsTypeDeclaration()
                     && TokenArray[ token_index - 1 ].Text.indexOf( "DLL" ) >= 0 );
        }
        else
        {
            return false;
        }
    }

    // ~~

    void FindTypes(
        )
    {
        long
            brace_level,
            token_index;
        long[]
            name_space_brace_level_array;
        TOKEN
            token;

        brace_level = 0;

        for ( token_index = 0;
              token_index < TokenArray.length;
              ++token_index )
        {
            token = TokenArray[ token_index ];

            if ( token.Type == TOKEN_TYPE.Identifier )
            {
                if ( IsNameSpaceDeclaration( token_index ) )
                {
                    name_space_brace_level_array ~= brace_level;
                }
                else if ( brace_level == name_space_brace_level_array.length
                          && IsTypeDeclaration( token_index ) )
                {
                    AddType( token.Text, IncludedFilePath );
                }
            }
            else if ( token.Type == TOKEN_TYPE.Delimiter )
            {
                if ( token.Text == "{" )
                {
                    ++brace_level;
                }
                else if ( token.Text == "}" )
                {
                    --brace_level;
                    
                    if ( name_space_brace_level_array.length > 0
                         && brace_level <= name_space_brace_level_array[ $ - 1 ] )
                    {
                        name_space_brace_level_array = name_space_brace_level_array[ 0 .. $ - 1 ];
                    }
                }
            }
        }
    }

    // ~~

    void FindMissingTypes(
        )
    {
        long
            brace_level,
            token_index;
        long[]
            name_space_brace_level_array;
        string
            type_name;
        string[]
            part_array;
        TOKEN
            token;

        if ( FilePath.HasInclusionExtension() )
        {
            AddDeclaredType( IncludedFilePath.GetTypeName() );
        }

        for ( token_index = 0;
              token_index < TokenArray.length;
              ++token_index )
        {
            token = TokenArray[ token_index ];

            if ( token.Type == TOKEN_TYPE.Identifier )
            {
                if ( IsNameSpaceDeclaration( token_index ) )
                {
                    name_space_brace_level_array ~= brace_level;
                }
                else if ( brace_level == name_space_brace_level_array.length
                          && ( IsTypeDeclaration( token_index )
                               || IsForwardTypeDeclaration( token_index ) ) )
                {
                    AddDeclaredType( token.Text );
                }
                else if ( token.Text == "#include"
                          && token_index + 2 < TokenArray.length
                          && TokenArray[ token_index + 1 ].Text == "\"" )
                {
                    AddDeclaredTypes( TokenArray[ token_index + 2 ].Text );
                }
                else if ( ( token.Text in TypeMap ) !is null )
                {
                    if ( !IsTypeDeclaration( token_index )
                         && !IsForwardTypeDeclaration( token_index )
                         && ( token_index == 0
                              || TokenArray[ token_index - 1 ].Text != "::" ) )
                    {
                        AddUsedType( token.Text );
                    }
                }
                else if ( PartialOptionIsEnabled )
                {
                    if ( ( token.Text in TypeMap ) is null
                         && token.Text.indexOf( '_' ) >= 0 )
                    {
                        part_array = token.Text.split( '_' );
                        
                        if ( part_array.length >= 2
                             && ( part_array[ $ - 1 ].length == 1
                                  || part_array[ $ - 1 ] != part_array[ $ - 1 ].toUpper() ) )
                        {
                            type_name = part_array[ 0 .. $ - 1 ].join( '_' );
                            
                            if ( ( type_name in TypeMap ) !is null )
                            {
                                AddUsedType( type_name );
                            }
                        }
                    }
                }
            }
            else if ( token.Type == TOKEN_TYPE.Delimiter )
            {
                if ( token.Text == "{" )
                {
                    ++brace_level;
                }
                else if ( token.Text == "}" )
                {
                    --brace_level;
                    
                    if ( name_space_brace_level_array.length > 0
                         && brace_level <= name_space_brace_level_array[ $ - 1 ] )
                    {
                        name_space_brace_level_array = name_space_brace_level_array[ 0 .. $ - 1 ];
                    }
                }
            }
        }

        foreach ( used_type; UsedTypeMap )
        {
            if ( ( used_type.Name in DeclaredTypeMap ) is null )
            {
                AddMissingType( used_type.Name );
            }
        }
    }

    // ~~

    void FindUnusedTypes(
        )
    {
        foreach ( declared_type; DeclaredTypeMap )
        {
            if ( declared_type.IncludedFilePath != ""
                 && ( declared_type.Name in UsedTypeMap ) is null )
            {
                AddUnusedType( declared_type.Name, declared_type.IncludedFilePath );
            }
        }
    }

    // ~~

    void AddMissingInclusions(
        )
    {
        bool
            empty_line_is_added;
        long
            best_include_line_index,
            comment_line_index,
            last_include_line_index,
            line_index;
        string
            best_include_indentation,
            best_include_line,
            comment_indentation,
            last_include_indentation,
            line,
            missing_line,
            stripped_line;
        string[]
            line_array;
        TYPE
            * type;

        line_array = FileText.split( '\n' );

        foreach ( missing_type; MissingTypeMap )
        {
            type = missing_type.Name in TypeMap;

            missing_line = "#include \"" ~ type.IncludedFilePath ~ "\"";

            best_include_line = "";
            best_include_line_index = -1;
            best_include_indentation = "";

            last_include_line_index = -1;
            last_include_indentation = "";

            comment_line_index = -1;
            comment_indentation = "";

            empty_line_is_added = false;

            for ( line_index = 0;
                  line_index < line_array.length;
                  ++line_index )
            {
                line = line_array[ line_index ];
                stripped_line = line.strip();

                if ( stripped_line.startsWith( "#include \"" ) )
                {
                    last_include_line_index = line_index;
                    last_include_indentation = line[ 0 .. line.indexOf( '#' ) ];

                    if ( stripped_line.startsWith( "#include \"" )
                         && missing_line < stripped_line
                         && ( best_include_line_index < 0
                              || stripped_line < best_include_line ) )
                    {
                        best_include_line = stripped_line;
                        best_include_line_index = line_index;
                        best_include_indentation = last_include_indentation;
                    }
                }
                else if ( Comment != ""
                          && stripped_line.startsWith( Comment ) )
                {
                    best_include_line = "";
                    best_include_line_index = -1;
                    best_include_indentation = "";

                    last_include_line_index = -1;
                    last_include_indentation = "";

                    comment_line_index = line_index;
                    comment_indentation = line[ 0 .. line.indexOf( Comment ) ];
                }
            }

            if ( best_include_line_index >= 0 )
            {
                empty_line_is_added = false;
            }
            else if ( last_include_line_index >= 0 )
            {
                best_include_line_index = last_include_line_index + 1;
                best_include_indentation = last_include_indentation;

                empty_line_is_added = false;
            }
            else if ( comment_line_index >= 0 )
            {
                best_include_line_index = comment_line_index + 1;
                best_include_indentation = comment_indentation;

                empty_line_is_added = true;
            }
            else
            {
                best_include_line_index = 0;

                if ( line_array.length >= 2
                     && line_array[ 0 ].strip().startsWith( "#ifndef __" )
                     && line_array[ 1 ].strip().startsWith( "#define __" ) )
                {
                    best_include_line_index = 2;
                    best_include_indentation = "    ";
                }

                empty_line_is_added = true;
            }

            if ( best_include_line_index > line_array.length )
            {
                best_include_line_index = line_array.length;
            }

            missing_line = best_include_indentation ~ missing_line;

            line_array
                = line_array[ 0 .. best_include_line_index ]
                  ~ missing_line
                  ~ line_array[ best_include_line_index .. $ ];

            if ( empty_line_is_added )
            {
                line_array
                    = line_array[ 0 .. best_include_line_index ]
                      ~ ""
                      ~ line_array[ best_include_line_index .. $ ];
            }
        }

        FileText = line_array.join( '\n' );
    }

    // ~~

    void SortInclusions(
        )
    {
        bool
            line_array_has_changed;
        int
            line_index;
        string
            line,
            next_line,
            stripped_line,
            stripped_next_line;
        string[]
            line_array;

        line_array = FileText.split( '\n' );

        do
        {
            line_array_has_changed = false;

            for ( line_index = 0;
                  line_index + 1 < line_array.length;
                  ++line_index )
            {
                line = line_array[ line_index ];
                next_line = line_array[ line_index + 1 ];

                stripped_line = line.strip();
                stripped_next_line = next_line.strip();

                if ( stripped_line.startsWith( "#include \"" )
                     && stripped_next_line.startsWith( "#include \"" ) )
                {
                    if ( stripped_line > stripped_next_line )
                    {
                        line_array[ line_index ] = next_line;
                        line_array[ line_index + 1 ] = line;

                        line_array_has_changed = true;
                    }
                    else if ( stripped_line == stripped_next_line )
                    {
                        line_array = line_array[ 0 .. line_index ] ~ line_array[ line_index + 1 .. $ ];
                        --line_index;

                        line_array_has_changed = true;
                    }
                }
            }
        }
        while ( line_array_has_changed );

        FileText = line_array.join( '\n' );
    }

    // ~~

    void Process(
        )
    {
        FindMissingTypes();

        if ( UnusedOptionIsEnabled )
        {
            FindUnusedTypes();
        }

        if ( MissingTypeMap.length > 0 )
        {
            AddMissingInclusions();
        }

        if ( SortOptionIsEnabled )
        {
            SortInclusions();
        }
    }
}

// == GLOBAL

// -- VARIABLES

bool
    ContentOptionIsEnabled,
    DebugOptionIsEnabled,
    FileNameOptionIsEnabled,
    MissingOptionIsEnabled,
    PartialOptionIsEnabled,
    PreviewOptionIsEnabled,
    PrintOptionIsEnabled,
    SortOptionIsEnabled,
    UnusedOptionIsEnabled,
    UpperCaseFileNameOptionIsEnabled,
    VerboseOptionIsEnabled;
string
    Comment;
TYPE[ string ]
    TypeMap;

// -- FUNCTIONS

void PrintError(
    string message
    )
{
    writeln( "*** ERROR : ", message );
}

// ~~

void PrintError(
    string message,
    Exception exception
    )
{
    PrintError( message );
    PrintError( exception.msg );
}

// ~~

void Abort(
    string message
    )
{
    PrintError( message );

    exit( -1 );
}

// ~~

void Abort(
    string message,
    Exception exception
    )
{
    PrintError( message, exception );

    exit( -1 );
}

// ~~

void Abort(
    string message,
    string line = "",
    string file_path = "",
    long line_index = 0
    )
{
    PrintError( message );

    if ( file_path != "" )
    {
        writeln( file_path, "(", ( line_index + 1 ), ") : ", line );
    }
    else if ( line != "" )
    {
        writeln( line );
    }

    throw new Exception( message ~ line );
}

// ~~

string ReadUnsafeText(
    string file_path
    )
{
    string
        file_text;

    try
    {
        file_text = file_path.readText();
    }
    catch ( Exception exception )
    {
        PrintError( "Can't read file : " ~ file_path, exception );
    }

    return file_text;
}

// ~~

string ReadText(
    string file_path
    )
{
    string
        file_text;

    try
    {
        file_text = file_path.readText();
    }
    catch ( FileException file_exception )
    {
        Abort( "Can't read file : " ~ file_path, file_exception );
    }

    return file_text;
}

// ~~

void WriteText(
    string file_path,
    string file_text
    )
{
    try
    {
        file_path.write( file_text );
    }
    catch ( FileException file_exception )
    {
        Abort( "Can't write file : " ~ file_path, file_exception );
    }
}

// ~~

bool IsNumberCharacter(
    char character,
    char prior_character,
    char next_character
    )
{
    return
        ( character >= '0' && character <= '9' )
        || ( character >= 'a' && character <= 'z' )
        || ( character >= 'A' && character <= 'Z' )
        || ( character == '.'
             && prior_character >= '0' && prior_character <= '9'
             && next_character >= '0' && next_character <= '9' )
        || ( character == '-'
             && ( prior_character == 'e' || prior_character == 'E' ) );
}

// ~~

bool IsIdentifierCharacter(
    char character
    )
{
    return
        ( character >= 'a' && character <= 'z' )
        || ( character >= 'A' && character <= 'Z' )
        || ( character >= '0' && character <= '9' )
        || character == '_';
}

// ~~

bool IsOperatorCharacter(
    char character
    )
{
    return
        character == '='
        || character == '+'
        || character == '-'
        || character == '*'
        || character == '/'
        || character == '%'
        || character == '<'
        || character == '>'
        || character == '~'
        || character == '&'
        || character == '|'
        || character == '^'
        || character == '!'
        || character == '?'
        || character == '@'
        || character == '#'
        || character == '$';
}

// ~~

bool IsSeparatorCharacter(
    char character
    )
{
    return
        character == ';'
        || character == ','
        || character == '.'
        || character == ':';
}

// ~~

bool IsDelimiterCharacter(
    char character
    )
{
    return
        character == '{'
        || character == '}'
        || character == '['
        || character == ']'
        || character == '('
        || character == ')';
}

// ~~

void Dump(
    TOKEN[] token_array
    )
{
    foreach ( token; token_array )
    {
        token.Dump();
    }
}

// ~~

string GetText(
    TOKEN[] token_array
    )
{
    string
        file_text;

    file_text = "";

    foreach ( ref token; token_array )
    {
        foreach ( line_index; 0 .. token.PriorLineCount )
        {
            file_text ~= "\n";
        }

        foreach ( space_index; 0 .. token.PriorSpaceCount )
        {
            file_text ~= " ";
        }

        file_text ~= token.Text;
    }

    file_text ~= "\n";

    return file_text;
}

// ~~

void SplitFilePath(
    string file_path,
    ref string folder_path,
    ref string file_name
    )
{
    long
        folder_path_character_count;

    folder_path_character_count = file_path.lastIndexOf( '/' ) + 1;

    folder_path = file_path[ 0 .. folder_path_character_count ];
    file_name = file_path[ folder_path_character_count .. $ ];
}

// ~~

void SplitFileName(
    string file_name,
    ref string base_name,
    ref string file_extension
    )
{
    long
        dot_character_index;

    dot_character_index = file_name.lastIndexOf( '.' );

    if ( dot_character_index >= 0 )
    {
        base_name = file_name[ 0 .. dot_character_index ];
        file_extension = file_name[ dot_character_index .. $ ];
    }
    else
    {
        base_name = file_name;
        file_extension = "";
    }
}

// ~~

void SplitFilePath(
    string file_path,
    ref string folder_path,
    ref string base_name,
    ref string file_extension
    )
{
    string
        file_name;

    SplitFilePath( file_path, folder_path, file_name );
    SplitFileName( file_name, base_name, file_extension );
}

// ~~

string GetFolderPath(
    string file_path
    )
{
    return file_path[ 0 .. file_path.lastIndexOf( '/' ) + 1 ];
}

// ~~

string GetFileName(
    string file_path
    )
{
    return file_path[ file_path.lastIndexOf( '/' ) + 1 .. $ ];
}

// ~~

string GetBaseName(
    string file_name
    )
{
    string
        base_name,
        file_extension;

    SplitFileName( file_name, base_name, file_extension );

    return base_name;
}

// ~~

string GetFileExtension(
    string file_name
    )
{
    string
        base_name,
        file_extension;

    SplitFileName( file_name, base_name, file_extension );

    return file_extension;
}

// ~~

void SplitFilePathFilter(
    string file_path_filter,
    ref string folder_path,
    ref string file_name_filter,
    ref SpanMode span_mode,
    ref long removed_character_count
    )
{
    removed_character_count = file_path_filter.lastIndexOf( '!' ) + 1;

    if ( removed_character_count > 0 )
    {
        --removed_character_count;

        file_path_filter
            = file_path_filter[ 0 .. removed_character_count ]
              ~ file_path_filter[ removed_character_count + 1 .. $ ];
    }

    SplitFilePath( file_path_filter, folder_path, file_name_filter );

    if ( folder_path.endsWith( "//" ) )
    {
        if ( removed_character_count == folder_path.length )
        {
            removed_character_count = -1;
        }
        
        folder_path = folder_path[ 0 .. $ - 1 ];

        span_mode = SpanMode.breadth;
    }
    else
    {
        span_mode = SpanMode.shallow;
    }

    if ( folder_path == "./" )
    {
        folder_path = "";

        if ( removed_character_count >= 2 )
        {
            removed_character_count -= 2;
        }
    }

    if ( removed_character_count >= folder_path.length.to!long() )
    {
        removed_character_count = folder_path.length;
    }
}

// ~~

string GetIncludedFilePath(
    string file_path,
    long removed_character_count
    )
{
    if ( removed_character_count > 0 )
    {
        return file_path[ removed_character_count .. $ ];
    }
    else if ( removed_character_count < 0 )
    {
        removed_character_count = file_path.lastIndexOf( '/' ) + 1;

        return file_path[ removed_character_count .. $ ];
    }
    else
    {
        return file_path;
    }
}

// ~~

string GetTypeName(
    string file_path
    )
{
    string
        file_extension,
        base_name,
        folder_path;

    SplitFilePath( file_path, folder_path, base_name, file_extension );

    if ( UpperCaseFileNameOptionIsEnabled )
    {
        return base_name.toUpper();
    }
    else
    {
        return base_name;
    }
}

// ~~

bool HasInclusionExtension(
    string file_path
    )
{
    return
        file_path.endsWith( ".h" )
        || file_path.endsWith( ".hpp" )
        || file_path.endsWith( ".ipp" )
        || file_path.endsWith( ".cxx" )
        || file_path.endsWith( ".hxx" )
        || file_path.endsWith( ".ixx" )
        || file_path.endsWith( ".inl" );
}

// ~~

bool HasType(
    string included_file_path
    )
{
    foreach ( type; TypeMap )
    {
        if ( type.IncludedFilePath == included_file_path )
        {
            return true;
        }
    }

    return false;
}

// ~~

void AddType(
    string type_name,
    string included_file_path
    )
{
    if ( VerboseOptionIsEnabled )
    {
        writeln( "    Including type : ", type_name, " (", included_file_path, ")" );
    }

    TypeMap[ type_name ] = new TYPE( type_name, included_file_path );
}

// ~~

void RemoveType(
    string type_name
    )
{
    if ( VerboseOptionIsEnabled )
    {
        writeln( "    Excluding type : ", type_name );
    }

    TypeMap.remove( type_name );
}

// ~~

void RemoveTypes(
    string included_file_path
    )
{
    string[]
        removed_type_name_array;

    foreach ( type; TypeMap )
    {
        if ( type.IncludedFilePath == included_file_path )
        {
            removed_type_name_array ~= type.Name;
        }
    }

    foreach ( removed_type_name; removed_type_name_array )
    {
        RemoveType( removed_type_name );
    }
}

// ~~

void IncludeFile(
    string file_path,
    string included_file_path
    )
{
    string
        file_text;
    CODE
        code;

    if ( VerboseOptionIsEnabled )
    {
        writeln( "Including file : ", included_file_path );
    }

    if ( ContentOptionIsEnabled )
    {
        file_text = file_path.ReadUnsafeText();

        code = new CODE;
        code.Set( file_text, file_path, included_file_path );
        code.FindTypes();
    }

    if ( ( FileNameOptionIsEnabled
           || UpperCaseFileNameOptionIsEnabled )
         && !HasType( included_file_path ) )
    {
        AddType( included_file_path.GetTypeName(), included_file_path );
    }
}

// ~~

void IncludeFiles(
    string file_path_filter
    )
{
    long
        removed_character_count;
    string
        file_name,
        file_name_filter,
        file_path,
        folder_path,
        included_file_path;
    SpanMode
        span_mode;

    if ( VerboseOptionIsEnabled )
    {
        writeln( "Including files : ", file_path_filter );
    }

    SplitFilePathFilter( file_path_filter, folder_path, file_name_filter, span_mode, removed_character_count );

    foreach (
        folder_entry;
        dirEntries( folder_path, span_mode )
        )
    {
        if ( folder_entry.isFile() )
        {
            file_path = folder_entry;
            file_name = file_path.GetFileName();

            if ( file_name.globMatch( file_name_filter ) )
            {
                IncludeFile( file_path, file_path.GetIncludedFilePath( removed_character_count ) );
            }
        }
    }
}

// ~~

void ExcludeFiles(
    string file_path_filter
    )
{
    long
        removed_character_count;
    string
        file_name,
        file_name_filter,
        file_path,
        folder_path,
        included_file_path;
    SpanMode
        span_mode;

    if ( VerboseOptionIsEnabled )
    {
        writeln( "Excluding files : ", file_path_filter );
    }

    SplitFilePathFilter( file_path_filter, folder_path, file_name_filter, span_mode, removed_character_count );

    foreach (
        folder_entry;
        dirEntries( folder_path, span_mode )
        )
    {
        if ( folder_entry.isFile() )
        {
            file_path = folder_entry;
            file_name = file_path.GetFileName();

            if ( file_name.globMatch( file_name_filter ) )
            {
                RemoveTypes( file_path.GetIncludedFilePath( removed_character_count ) );
            }
        }
    }
}

// ~~

void ProcessFile(
    string file_path
    )
{
    string
        file_text,
        included_file_path;
    CODE
        code;

    if ( VerboseOptionIsEnabled )
    {
        writeln( "Reading file : ", file_path );
    }

    file_text = file_path.ReadText();

    if ( file_path.HasInclusionExtension() )
    {
        included_file_path = file_path;
    }

    code = new CODE;
    code.Set( file_text, file_path, included_file_path );
    code.Process();

    if ( code.FileText != file_text )
    {
        if ( VerboseOptionIsEnabled )
        {
            writeln( "Writing file : ", file_path );
        }

        if ( PrintOptionIsEnabled )
        {
            writeln( code.FileText );
        }

        if ( !PreviewOptionIsEnabled )
        {
            file_path.WriteText( code.FileText );
        }
    }
}

// ~~

void ProcessFiles(
    string file_path_filter
    )
{
    long
        removed_character_count;
    string
        file_name,
        file_name_filter,
        file_path,
        folder_path;
    SpanMode
        span_mode;

    SplitFilePathFilter( file_path_filter, folder_path, file_name_filter, span_mode, removed_character_count );

    foreach (
        folder_entry;
        dirEntries( folder_path, span_mode )
        )
    {
        if ( folder_entry.isFile() )
        {
            file_path = folder_entry;
            file_name = file_path.GetFileName();

            if ( file_name.globMatch( file_name_filter ) )
            {
                ProcessFile( file_path );
            }
        }
    }
}

// ~~

void main(
    string[] argument_array
    )
{
    string
        option;

    argument_array = argument_array[ 1 .. $ ];

    Comment = "";
    ContentOptionIsEnabled = false;
    FileNameOptionIsEnabled = false;
    UpperCaseFileNameOptionIsEnabled = false;
    PartialOptionIsEnabled = false;
    MissingOptionIsEnabled = false;
    UnusedOptionIsEnabled = false;
    SortOptionIsEnabled = false;
    VerboseOptionIsEnabled = false;
    DebugOptionIsEnabled = false;
    PrintOptionIsEnabled = false;
    PreviewOptionIsEnabled = false;

    if ( argument_array.countUntil( "--verbose" ) >= 0 )
    {
        VerboseOptionIsEnabled = true;
    }

    while ( argument_array.length >= 1
            && argument_array[ 0 ].startsWith( "--" ) )
    {
        option = argument_array[ 0 ];

        argument_array = argument_array[ 1 .. $ ];

        if ( option == "--use_file_content" )
        {
            ContentOptionIsEnabled = true;
            FileNameOptionIsEnabled = false;
            UpperCaseFileNameOptionIsEnabled = false;
        }
        else if ( option == "--use_file_name" )
        {
            FileNameOptionIsEnabled = true;
            ContentOptionIsEnabled = false;
            UpperCaseFileNameOptionIsEnabled = false;
        }
        else if ( option == "--use_upper_case_file_name" )
        {
            UpperCaseFileNameOptionIsEnabled = true;
            ContentOptionIsEnabled = false;
            FileNameOptionIsEnabled = false;
        }
        else if ( option == "--or_file_name" )
        {
            FileNameOptionIsEnabled = true;
        }
        else if ( option == "--or_upper_case_file_name" )
        {
            UpperCaseFileNameOptionIsEnabled = true;
        }
        else if ( option == "--include"
                  && argument_array.length >= 1 )
        {
            IncludeFiles( argument_array[ 0 ] );

            argument_array = argument_array[ 1 .. $ ];
        }
        else if ( option == "--exclude"
                  && argument_array.length >= 1 )
        {
            ExcludeFiles( argument_array[ 0 ] );

            argument_array = argument_array[ 1 .. $ ];
        }
        else if ( option == "--comment"
                  && argument_array.length >= 1 )
        {
            Comment = argument_array[ 0 ];

            argument_array = argument_array[ 1 .. $ ];
        }
        else if ( option == "--partial" )
        {
            PartialOptionIsEnabled = true;
        }
        else if ( option == "--missing" )
        {
            MissingOptionIsEnabled = true;
        }
        else if ( option == "--unused" )
        {
            UnusedOptionIsEnabled = true;
        }
        else if ( option == "--sort" )
        {
            SortOptionIsEnabled = true;
        }
        else if ( option == "--verbose" )
        {
            VerboseOptionIsEnabled = true;
        }
        else if ( option == "--debug" )
        {
            DebugOptionIsEnabled = true;
        }
        else if ( option == "--print" )
        {
            PrintOptionIsEnabled = true;
        }
        else if ( option == "--preview" )
        {
            PreviewOptionIsEnabled = true;
        }
        else
        {
            Abort( "Invalid option : " ~ option );
        }
    }

    if ( argument_array.length >= 1 )
    {
        while ( argument_array.length >= 1 )
        {
            ProcessFiles( argument_array[ 0 ] );

            argument_array = argument_array[ 1 .. $ ];
        }
    }
    else
    {
        writeln( "Usage : inclean [options] file_path_filter ..." );
        writeln( "Options :" );
        writeln( "    --use_file_content" );
        writeln( "    --use_file_name" );
        writeln( "    --use_upper_case_file_name" );
        writeln( "    --or_file_name" );
        writeln( "    --or_upper_case_file_name" );
        writeln( "    --include \"INCLUDE_FOLDER/*.hpp\"" );
        writeln( "    --include \"INCLUDE_FOLDER/!*.hpp\"" );
        writeln( "    --include \"INCLUDE_FOLDER//*.hpp\"" );
        writeln( "    --include \"INCLUDE_FOLDER/!/*.hpp\"" );
        writeln( "    --include \"INCLUDE_FOLDER//!*.hpp\"" );
        writeln( "    --exclude \"INCLUDE_FOLDER/*.hpp\"" );
        writeln( "    --exclude \"INCLUDE_FOLDER//*.hpp\"" );
        writeln( "    --comment \"// -- IMPORTS\"" );
        writeln( "    --partial" );
        writeln( "    --missing" );
        writeln( "    --unused" );
        writeln( "    --sort" );
        writeln( "    --verbose" );
        writeln( "    --debug" );
        writeln( "    --print" );
        writeln( "    --preview" );
        writeln( "Example :" );
        writeln( "    inclean --upper_case --include \"*.hpp\" --include \"INCLUDE_FOLDER/!/*.hpp\" --comment \"// -- IMPORTS\" --partial --missing --sort --verbose \"*.hpp\" \"*.cpp\"" );

        Abort( "Invalid arguments : " ~ argument_array.to!string() );
    }
}
