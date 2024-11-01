//
//  SharedPreferences+Proxy.swift
//  Library
//
//  Created by  mac user 2 on 07.10.2024.
//
 
import BinaryCodable
import Foundation
import GRDB

extension SharedPreferences {
    private static let doAllTraficByDefault = true
    public static let doAllTrafic = Preference<Bool>("do_all_trafic", defaultValue: doAllTraficByDefault)

}
