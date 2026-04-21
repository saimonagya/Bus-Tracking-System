"use client";

import { useEffect, useMemo, useRef } from "react";
import { Crosshair } from "lucide-react";
import "ol/ol.css";
import Feature from "ol/Feature";
import Map from "ol/Map";
import Overlay from "ol/Overlay";
import View from "ol/View";
import { defaults as defaultControls } from "ol/control";
import type { Coordinate as OlCoordinate } from "ol/coordinate";
import { boundingExtent } from "ol/extent";
import LineString from "ol/geom/LineString";
import Point from "ol/geom/Point";
import TileLayer from "ol/layer/Tile";
import VectorLayer from "ol/layer/Vector";
import { fromLonLat } from "ol/proj";
import OSM from "ol/source/OSM";
import VectorSource from "ol/source/Vector";
import { Circle as CircleStyle, Fill, Stroke, Style, Text } from "ol/style";

import type { BusState, Coordinate } from "@/lib/types";

type RouteMapProps = {
  buses: BusState[];
  selectedBusId: number | null;
  viewerLocation: Coordinate | null;
  viewerLabel: string;
  locateLabel: string;
  onLocateViewer: () => void;
  onSelectBus?: (busId: number) => void;
};

const defaultCenter: [number, number] = [27.3098, 88.5964];
const defaultCenterMercator = fromLonLat([defaultCenter[1], defaultCenter[0]]);

const routeStyle = new Style({
  stroke: new Stroke({
    color: "rgba(34, 197, 94, 0.85)",
    width: 6
  })
});

const stopStyle = new Style({
  image: new CircleStyle({
    radius: 8,
    fill: new Fill({ color: "#86efac" }),
    stroke: new Stroke({ color: "#ffffff", width: 3 })
  })
});

const viewerStyle = new Style({
  image: new CircleStyle({
    radius: 16,
    fill: new Fill({ color: "#0ea5e9" }),
    stroke: new Stroke({ color: "#ffffff", width: 4 })
  }),
  text: new Text({
    text: "◎",
    fill: new Fill({ color: "#ffffff" }),
    font: "bold 14px Segoe UI, sans-serif"
  })
});

function busStyle(selected: boolean) {
  return new Style({
    image: new CircleStyle({
      radius: 18,
      fill: new Fill({ color: selected ? "#10b981" : "#0f172a" }),
      stroke: new Stroke({ color: "#ffffff", width: 4 })
    }),
    text: new Text({
      text: "BUS",
      fill: new Fill({ color: "#ffffff" }),
      font: "700 10px Segoe UI, sans-serif"
    })
  });
}

function toMapCoordinate(point: Coordinate): OlCoordinate {
  return fromLonLat([point.lng, point.lat]);
}

export function RouteMap({
  buses,
  selectedBusId,
  viewerLocation,
  viewerLabel,
  locateLabel,
  onLocateViewer,
  onSelectBus
}: RouteMapProps) {
  const mapElementRef = useRef<HTMLDivElement | null>(null);
  const tooltipElementRef = useRef<HTMLDivElement | null>(null);
  const mapRef = useRef<Map | null>(null);
  const vectorSourceRef = useRef<VectorSource | null>(null);
  const onSelectBusRef = useRef<typeof onSelectBus>(onSelectBus);

  const selectedBus = useMemo(
    () => buses.find((bus) => bus.id === selectedBusId) ?? buses[0] ?? null,
    [buses, selectedBusId]
  );

  useEffect(() => {
    onSelectBusRef.current = onSelectBus;
  }, [onSelectBus]);

  useEffect(() => {
    if (!mapElementRef.current || !tooltipElementRef.current || mapRef.current) {
      return;
    }

    const vectorSource = new VectorSource();
    vectorSourceRef.current = vectorSource;

    const vectorLayer = new VectorLayer({
      source: vectorSource
    });

    const tooltipOverlay = new Overlay({
      element: tooltipElementRef.current,
      offset: [0, -16],
      positioning: "bottom-center",
      stopEvent: false
    });

    const map = new Map({
      target: mapElementRef.current,
      layers: [
        new TileLayer({
          source: new OSM()
        }),
        vectorLayer
      ],
      overlays: [tooltipOverlay],
      controls: defaultControls({
        zoom: false,
        rotate: false
      }),
      view: new View({
        center: defaultCenterMercator,
        zoom: 12
      })
    });

    map.on("pointermove", (event) => {
      if (!tooltipElementRef.current) {
        return;
      }

      const feature = map.forEachFeatureAtPixel(event.pixel, (candidate) => candidate as Feature<Point>);
      const label = feature?.get("label") as string | undefined;

      if (label) {
        tooltipElementRef.current.textContent = label;
        tooltipOverlay.setPosition(event.coordinate);
      } else {
        tooltipOverlay.setPosition(undefined);
      }
    });

    map.on("singleclick", (event) => {
      const handleSelect = onSelectBusRef.current;
      if (!handleSelect) {
        return;
      }

      const feature = map.forEachFeatureAtPixel(event.pixel, (candidate) => candidate as Feature<Point>);
      const busId = feature?.get("busId");
      if (typeof busId === "number") {
        handleSelect(busId);
      }
    });

    mapRef.current = map;

    return () => {
      map.setTarget(undefined);
      mapRef.current = null;
      vectorSourceRef.current = null;
    };
  }, []);

  useEffect(() => {
    const map = mapRef.current;
    const vectorSource = vectorSourceRef.current;

    if (!map || !vectorSource) {
      return;
    }

    vectorSource.clear();

    const mapPoints: OlCoordinate[] = [];

    if (selectedBus?.route?.length) {
      const coordinates = selectedBus.route.map((point) => {
        const coord = toMapCoordinate(point);
        mapPoints.push(coord);
        return coord;
      });

      const routeFeature = new Feature({
        geometry: new LineString(coordinates)
      });
      routeFeature.setStyle(routeStyle);
      vectorSource.addFeature(routeFeature);
    }

    for (const stop of selectedBus?.stops ?? []) {
      const coordinate = toMapCoordinate(stop.coordinate);
      mapPoints.push(coordinate);
      const feature = new Feature({
        geometry: new Point(coordinate),
        label: stop.name
      });
      feature.setStyle(stopStyle);
      vectorSource.addFeature(feature);
    }

    for (const bus of buses) {
      if (!bus.position) {
        continue;
      }

      const coordinate = toMapCoordinate(bus.position);
      mapPoints.push(coordinate);
      const feature = new Feature({
        geometry: new Point(coordinate),
        label: bus.name,
        busId: bus.id
      });
      feature.setStyle(busStyle(bus.id === selectedBus?.id));
      vectorSource.addFeature(feature);
    }

    if (viewerLocation) {
      const coordinate = toMapCoordinate(viewerLocation);
      mapPoints.push(coordinate);
      const feature = new Feature({
        geometry: new Point(coordinate),
        label: viewerLabel
      });
      feature.setStyle(viewerStyle);
      vectorSource.addFeature(feature);
    }

    const view = map.getView();

    if (mapPoints.length >= 2) {
      view.fit(boundingExtent(mapPoints), {
        padding: [60, 60, 60, 60],
        duration: 250,
        maxZoom: 15
      });
      return;
    }

    if (mapPoints.length === 1) {
      view.animate({ center: mapPoints[0], zoom: 13, duration: 250 });
      return;
    }

    view.animate({ center: defaultCenterMercator, zoom: 12, duration: 250 });
  }, [buses, selectedBus, viewerLabel, viewerLocation]);

  return (
    <div className="relative h-full w-full">
      <div ref={mapElementRef} className="h-full w-full" />
      <div
        ref={tooltipElementRef}
        className="pointer-events-none rounded-md border border-white/10 bg-slate-950/85 px-3 py-1 text-xs font-semibold text-white shadow-lg"
      />

      <button
        type="button"
        onClick={onLocateViewer}
        className="absolute right-4 top-4 z-10 flex items-center gap-2 rounded-full border border-white/10 bg-slate-950/85 px-4 py-3 text-sm font-semibold text-white shadow-lg backdrop-blur-md"
      >
        <Crosshair className="h-4 w-4 text-emerald-300" />
        {locateLabel}
      </button>
    </div>
  );
}
