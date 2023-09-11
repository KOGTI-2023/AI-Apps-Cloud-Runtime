package codeSnippet

import (
	"context"

	netstat "github.com/drael/GOnetstat"
	"github.com/e2b-dev/api/packages/envd/internal/port"
	"github.com/e2b-dev/api/packages/envd/internal/subscriber"
	"github.com/ethereum/go-ethereum/rpc"
	"go.uber.org/zap"
)

type Service struct {
	logger *zap.SugaredLogger

	scanOpenedPortsSubs *subscriber.Manager
	scannerSubscriber   *port.ScannerSubscriber
}

func NewService(
	logger *zap.SugaredLogger,
	portScanner *port.Scanner,
) *Service {
	scannerSub := portScanner.AddSubscriber(
		"code-snippet-service",
		nil,
	)

	cs := &Service{
		logger:              logger,
		scannerSubscriber:   scannerSub,
		scanOpenedPortsSubs: subscriber.NewManager("codeSnippet/scanOpenedPortsSubs", logger.Named("subscriber.codeSnippet.scanOpenedPorts")),
	}

	go cs.listenToOpenPorts()

	return cs
}

func (s *Service) listenToOpenPorts() {
	for {
		if procs, ok := <-s.scannerSubscriber.Messages; ok {
			s.notifyScanOpenedPorts(procs)
		}
	}
}

func (s *Service) notifyScanOpenedPorts(ports []netstat.Process) {
	err := s.scanOpenedPortsSubs.Notify("", ports)
	if err != nil {
		s.logger.Errorw("Failed to send scan opened ports notification",
			"error", err,
		)
	}
}

// Subscription
func (s *Service) ScanOpenedPorts(ctx context.Context) (*rpc.Subscription, error) {
	s.logger.Info("Subscribe to scanning open ports")

	sub, _, err := s.scanOpenedPortsSubs.Create(ctx, "")
	if err != nil {
		s.logger.Errorw("Failed to create a scan opened ports subscription from context",
			"ctx", ctx,
			"error", err,
		)

		return nil, err
	}

	return sub.Subscription, nil
}
