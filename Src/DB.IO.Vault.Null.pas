{
 * This Source Code Form is subject to the terms of the Mozilla Public License,
 * v. 2.0. If a copy of the MPL was not distributed with this file, You can
 * obtain one at https://mozilla.org/MPL/2.0/
 *
 * Copyright (C) 2008-2021, Peter Johnson (gravatar.com/delphidabbler).
 *
 * Implements a do nothing data reader for use when a database does not exist.
}


unit DB.IO.Vault.Null;


interface


uses
  // Project
  DB.MetaData,
  DB.UCategory,
  DB.USnippet,
  DB.IO.Vault,
  UIStringList;


type

  ///  <summary>A do nothing vault data reader used when no vaults exist.
  ///  </summary>
  TNullVaultStorageReader = class(TInterfacedObject,
    IVaultStorageReader
  )
  public
    { IDataReader methods }
    function DatabaseExists: Boolean;
      {Checks if the database exists. This method is always called first. No
      other methods are called if this method returns false.
        @return Always returns True. It always can read a do-nothing database.
      }
    function GetAllCatIDs: IStringList;
      {Gets ids of all categories in database.
        @return Empty string list.
      }
    procedure GetCatProps(const CatID: string; var Props: TCategoryData);
      {Gets properties of a category.
        @param CatID [in] Id of required category.
        @param Props [in/out] Empty properties passed in. Unchanged.
      }
    function GetCatSnippets(const CatID: string): IStringList;
      {Gets keys of all snippets in a category.
        @param CatID [in] Id of category containing snippets.
        @return Empty snippet key list.
      }
    procedure GetSnippetProps(const SnippetKey: string;
      var Props: TSnippetData);
      {Gets properties of a snippet. These are the fields of the snippet's
      record in the snippets "table".
        @param SnippetKey [in] Keys of required snippet.
        @param Props [in/out] Empty properties passed in. Unchanged.
      }
    function GetSnippetXRefs(const SnippetKey: string): IStringList;
      {Gets list of all snippets that are cross referenced by a snippet.
        @param SnippetKey [in] Key of snippet we need cross references for.
        @return Empty snippet key list.
      }
    function GetSnippetDepends(const SnippetKey: string): IStringList;
      {Gets list of all snippets on which a given snippet depends.
        @param SnippetKey [in] Key of required snippet.
        @return Empty snippet key list.
      }
    function GetSnippetUnits(const SnippetKey: string): IStringList;
      {Gets list of all units referenced by a snippet.
        @param SnippetKey [in] Key of required snippet.
        @return Empty unit name list.
      }

    ///  <summary>Gets the vault's meta data.</summary>
    ///  <returns><c>TMetaData</c>. Null value.</returns>
    ///  <remarks>Method of <c>IDataReader</c>.</remarks>
    function GetMetaData: TMetaData;
  end;


implementation


{ TNullVaultStorageReader }

function TNullVaultStorageReader.DatabaseExists: Boolean;
  {Checks if the database exists. This method is always called first. No other
  methods are called if this method returns false.
    @return Always returns True. It always can read a do-nothing database.
  }
begin
  Result := True;
end;

function TNullVaultStorageReader.GetAllCatIDs: IStringList;
  {Gets ids of all categories in database.
    @return Empty string list.
  }
begin
  Result := TIStringList.Create;
end;

procedure TNullVaultStorageReader.GetCatProps(const CatID: string;
  var Props: TCategoryData);
  {Gets properties of a category.
    @param CatID [in] Id of required category.
    @param Props [in/out] Empty properties passed in. Unchanged.
  }
begin
  // Do nothing
end;

function TNullVaultStorageReader.GetCatSnippets(const CatID: string):
  IStringList;
  {Gets keys of all snippets in a category.
    @param CatID [in] Id of category containing snippets.
    @return Empty snippey key list.
  }
begin
  Result := TIStringList.Create;
end;

function TNullVaultStorageReader.GetMetaData: TMetaData;
begin
  Result := TMetaData.CreateNull;
end;

function TNullVaultStorageReader.GetSnippetDepends(const SnippetKey: string):
  IStringList;
  {Gets list of all snippets on which a given snippet depends.
    @param SnippetKey [in] Key of required snippet.
    @return Empty snippet key list.
  }
begin
  Result := TIStringList.Create;
end;

procedure TNullVaultStorageReader.GetSnippetProps(const SnippetKey: string;
  var Props: TSnippetData);
  {Gets properties of a snippet. These are the fields of the snippet's record in
  the snippets "table".
    @param SnippetKey [in] Key of required snippet.
    @param Props [in/out] Empty properties passed in. Unchanged.
  }
begin
  // Do nothing
end;

function TNullVaultStorageReader.GetSnippetUnits(const SnippetKey: string):
  IStringList;
  {Gets list of all units referenced by a snippet.
    @param SnippetKey [in] Key of required snippet.
    @return Empty unit name list.
  }
begin
  Result := TIStringList.Create;
end;

function TNullVaultStorageReader.GetSnippetXRefs(const SnippetKey: string):
  IStringList;
  {Gets list of all snippets that are cross referenced by a snippet.
    @param SnippetKey [in] Key of snippet we need cross references for.
    @return Empty snippet key list.
  }
begin
  Result := TIStringList.Create;
end;

end.

