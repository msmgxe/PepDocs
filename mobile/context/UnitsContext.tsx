import React, { createContext, useContext, useEffect, useState } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';

export type WeightUnit = 'kg' | 'lbs';
export type HeightUnit = 'cm' | 'ft';

// ── Conversion helpers ──────────────────────────────────────────────────────

export function kgToLbs(kg: number): number {
  return parseFloat((kg * 2.20462).toFixed(1));
}

export function lbsToKg(lbs: number): number {
  return parseFloat((lbs / 2.20462).toFixed(2));
}

export function cmToFtIn(cm: number): { ft: number; inch: number } {
  const totalIn = cm / 2.54;
  const ft = Math.floor(totalIn / 12);
  const inch = Math.round(totalIn % 12);
  return { ft, inch };
}

export function formatWeight(kg: number, unit: WeightUnit): string {
  return unit === 'kg' ? `${kg} kg` : `${kgToLbs(kg)} lbs`;
}

export function formatHeight(cm: number, unit: HeightUnit): string {
  if (unit === 'cm') return `${cm} cm`;
  const { ft, inch } = cmToFtIn(cm);
  return `${ft}'${inch}"`;
}

// ── Context ─────────────────────────────────────────────────────────────────

interface UnitsContextType {
  weightUnit: WeightUnit;
  setWeightUnit: (unit: WeightUnit) => void;
  heightUnit: HeightUnit;
  setHeightUnit: (unit: HeightUnit) => void;
}

const UnitsContext = createContext<UnitsContextType | undefined>(undefined);

export function UnitsProvider({ children }: { children: React.ReactNode }) {
  const [weightUnit, setWeightUnitState] = useState<WeightUnit>('kg');
  const [heightUnit, setHeightUnitState] = useState<HeightUnit>('cm');

  useEffect(() => {
    async function loadPrefs() {
      const [w, h] = await Promise.all([
        AsyncStorage.getItem('pep-weight-unit'),
        AsyncStorage.getItem('pep-height-unit'),
      ]);
      if (w === 'kg' || w === 'lbs') setWeightUnitState(w);
      if (h === 'cm' || h === 'ft') setHeightUnitState(h);
    }
    loadPrefs();
  }, []);

  const setWeightUnit = (unit: WeightUnit) => {
    setWeightUnitState(unit);
    AsyncStorage.setItem('pep-weight-unit', unit);
  };

  const setHeightUnit = (unit: HeightUnit) => {
    setHeightUnitState(unit);
    AsyncStorage.setItem('pep-height-unit', unit);
  };

  return (
    <UnitsContext.Provider value={{ weightUnit, setWeightUnit, heightUnit, setHeightUnit }}>
      {children}
    </UnitsContext.Provider>
  );
}

export function useUnits() {
  const context = useContext(UnitsContext);
  if (!context) throw new Error('useUnits must be used within a UnitsProvider');
  return context;
}
