"use client";

import { useEffect, useMemo } from "react";
import L from "leaflet";
import { Crosshair } from "lucide-react";
import { MapContainer, Marker, Polyline, TileLayer, Tooltip, useMap } from "react-leaflet";

import type { BusState, Coordinate } from "@/lib/types";

type RouteMapProps = {
  busState: BusState | null;
  userLocation: Coordinate | null;
  onLocateUser: () => void;
};

const defaultCenter: [number, number] = [27.3098, 88.5984];

function iconFromSvg(svg: string) {
  return L.divIcon({
    html: svg,
    className: "",
    iconSize: [40, 40],
    iconAnchor: [20, 20]
  });
}

const busIcon = iconFromSvg(
  '<div style="display:flex;height:40px;width:40px;align-items:center;justify-content:center;border-radius:9999px;border:4px solid #fff;background:#22c55e;color:#fff;box-shadow:0 10px 24px rgba(15,23,42,0.25);font-size:10px;font-weight:700;letter-spacing:0.08em;">BUS</div>'
);

const userIcon = iconFromSvg(
  '<div style="display:flex;height:32px;width:32px;align-items:center;justify-content:center;border-radius:9999px;border:4px solid #fff;background:#0ea5e9;color:#fff;box-shadow:0 10px 24px rgba(15,23,42,0.25);font-size:14px;">◎</div>'
);

const waypointIcon = iconFromSvg(
  '<div style="height:14px;width:14px;border-radius:9999px;border:3px solid #fff;background:#86efac;box-shadow:0 4px 12px rgba(15,23,42,0.2);"></div>'
);

export function RouteMap({ busState, userLocation, onLocateUser }: RouteMapProps) {
  const routeCoordinates = useMemo(
    () => (busState?.route ?? []).map((point) => [point.lat, point.lng] as [number, number]),
    [busState?.route]
  );

  return (
    <div className="relative h-screen w-full">
      <MapContainer
        center={defaultCenter}
        zoom={13}
        scrollWheelZoom
        className="h-full w-full"
        zoomControl={false}
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/">CARTO</a>'
          url="https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
        />
        {routeCoordinates.length > 0 ? (
          <Polyline positions={routeCoordinates} pathOptions={{ color: "#22c55e", weight: 6, opacity: 0.85 }} />
        ) : null}

        {busState?.waypoints.map((point) => (
          <Marker
            key={point.name}
            position={[point.coordinate.lat, point.coordinate.lng]}
            icon={waypointIcon}
          >
            <Tooltip direction="top" offset={[0, -12]} opacity={0.95}>
              {point.name}
            </Tooltip>
          </Marker>
        ))}

        {busState?.is_active ? (
          <Marker position={[busState.position.lat, busState.position.lng]} icon={busIcon}>
            <Tooltip direction="top" offset={[0, -12]} opacity={0.95}>
              {busState.bus_name}
            </Tooltip>
          </Marker>
        ) : null}

        {userLocation ? <Marker position={[userLocation.lat, userLocation.lng]} icon={userIcon} /> : null}

        <MapViewport busState={busState} userLocation={userLocation} />
      </MapContainer>

      <button
        type="button"
        onClick={onLocateUser}
        className="absolute right-4 top-28 z-[900] flex items-center gap-2 rounded-full border border-white/15 bg-slate-950/85 px-4 py-3 text-sm font-semibold text-white shadow-lg backdrop-blur-md"
      >
        <Crosshair className="h-4 w-4 text-emerald-300" />
        Locate me
      </button>
    </div>
  );
}

function MapViewport({
  busState,
  userLocation
}: {
  busState: BusState | null;
  userLocation: Coordinate | null;
}) {
  const map = useMap();

  useEffect(() => {
    const points: L.LatLngExpression[] = [];

    if (busState?.route?.length) {
      for (const point of busState.route) {
        points.push([point.lat, point.lng]);
      }
    }

    if (userLocation) {
      points.push([userLocation.lat, userLocation.lng]);
    }

    if (points.length >= 2) {
      map.fitBounds(points, { padding: [60, 60] });
      return;
    }

    if (busState?.position) {
      map.setView([busState.position.lat, busState.position.lng], 13);
    }
  }, [busState, map, userLocation]);

  return null;
}
